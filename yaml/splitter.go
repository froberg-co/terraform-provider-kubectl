package yaml

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"strings"

	yamlParser "gopkg.in/yaml.v2"
	utilyaml "k8s.io/apimachinery/pkg/util/yaml"
)

// SplitMultiDocumentYAML splits a multi-document YAML string into its
// constituent documents. Empty documents (whitespace-only or
// comments-only) are skipped. Each returned document is the document
// body with surrounding whitespace trimmed.
//
// The splitter is YAML-aware (delegating to
// k8s.io/apimachinery/pkg/util/yaml.NewYAMLReader), so document
// separators (`---`) appearing inside quoted strings or block scalars
// do NOT cause false splits.
func SplitMultiDocumentYAML(multidoc string) (documents []string, err error) {
	reader := utilyaml.NewYAMLReader(bufio.NewReader(bytes.NewReader([]byte(multidoc))))
	for {
		raw, readErr := reader.Read()
		if errors.Is(readErr, io.EOF) {
			break
		}
		if readErr != nil {
			return documents, fmt.Errorf("error reading multi-document YAML: %w", readErr)
		}

		document := strings.TrimSpace(string(raw))
		if document == "" {
			continue
		}

		// Parse the document so the caller never receives an
		// uncompilable document, and so we can skip
		// comment-only/whitespace-only docs that survived TrimSpace.
		rawYamlParsed := &map[string]interface{}{}
		if err := yamlParser.Unmarshal([]byte(document), rawYamlParsed); err != nil {
			return documents, fmt.Errorf("error parsing yaml document: %v\n%v", err, document)
		}
		if len(*rawYamlParsed) == 0 {
			continue
		}

		documents = append(documents, document)
	}
	return documents, nil
}
