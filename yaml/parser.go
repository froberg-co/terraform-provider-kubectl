package yaml

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"strings"

	"github.com/icza/dyno"
	yamlParser "gopkg.in/yaml.v2"
	meta_v1_unstruct "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// ParseYAML parses a single-document YAML string into a Manifest.
//
// To make things play nice we need the JSON representation of the
// object as the RawObj:
//  1. unmarshal YAML into a map
//  2. marshal that map into JSON
//  3. unmarshal the JSON into an Unstructured so we get k8s type checking
//
// If the input contains more than one YAML document, ParseYAML returns
// an error rather than silently dropping the trailing documents (the
// underlying gopkg.in/yaml.v2 Unmarshal only decodes the first one).
// Callers with multi-document input should call SplitMultiDocumentYAML
// first and feed each document into ParseYAML individually.
func ParseYAML(yaml string) (*Manifest, error) {
	// Decode the first document, then probe for a second to detect the
	// silent-data-loss case.
	decoder := yamlParser.NewDecoder(strings.NewReader(yaml))
	rawYamlParsed := map[string]interface{}{}
	if err := decoder.Decode(&rawYamlParsed); err != nil {
		// EOF on the very first Decode means the input was empty or
		// whitespace-only — preserve the old behaviour and return a
		// Manifest wrapping an empty Unstructured (callers check
		// GetKind/GetName afterwards).
		if err == io.EOF {
			rawYamlParsed = map[string]interface{}{}
		} else {
			return nil, err
		}
	}
	var probe map[string]interface{}
	if err := decoder.Decode(&probe); err == nil && len(probe) > 0 {
		return nil, fmt.Errorf("ParseYAML accepts a single YAML document; got multiple — call SplitMultiDocumentYAML first and parse each piece individually")
	}

	rawJSON, err := json.Marshal(dyno.ConvertMapI2MapS(rawYamlParsed))
	if err != nil {
		return nil, err
	}

	unstruct := meta_v1_unstruct.Unstructured{}
	if err := unstruct.UnmarshalJSON(rawJSON); err != nil {
		return nil, err
	}

	manifest := &Manifest{Raw: &unstruct}

	// Log only the identifying metadata at DEBUG. Previously this dumped
	// the full UnstructuredContent which includes Secret data/stringData
	// — anyone running with TF_LOG=DEBUG ended up with Secret material
	// in their log archives. If you need the full payload for debugging,
	// fetch it from the live cluster with
	// `kubectl get <kind>/<name> -n <namespace> -o yaml`.
	log.Printf("[DEBUG] %s parsed manifest: apiVersion=%s kind=%s namespace=%s name=%s",
		manifest, manifest.GetAPIVersion(), manifest.GetKind(), manifest.GetNamespace(), manifest.GetName())
	return manifest, nil
}
