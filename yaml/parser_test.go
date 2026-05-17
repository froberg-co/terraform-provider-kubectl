package yaml

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestParseYAML_SingleDocument(t *testing.T) {
	m, err := ParseYAML(`
apiVersion: v1
kind: ConfigMap
metadata:
  name: example
  namespace: default
data:
  key: value
`)
	assert.NoError(t, err)
	assert.Equal(t, "v1", m.GetAPIVersion())
	assert.Equal(t, "ConfigMap", m.GetKind())
	assert.Equal(t, "example", m.GetName())
	assert.Equal(t, "default", m.GetNamespace())
}

func TestParseYAML_RejectsMultiDocumentInput(t *testing.T) {
	// Regression: previously this would silently parse the first doc
	// and drop the second. ParseYAML must surface the multi-doc case
	// as an error so callers know to split.
	multi := `
apiVersion: v1
kind: ConfigMap
metadata:
  name: first
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: second
`
	_, err := ParseYAML(multi)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "single YAML document")
}

func TestParseYAML_EmptyInputErrors(t *testing.T) {
	// Empty / whitespace-only / comment-only input has no Kind and
	// therefore can't be turned into an Unstructured — that surfaces
	// as a clear error rather than silently producing a zero-valued
	// Manifest the caller has no way to detect.
	cases := []string{"", "   \n  \n", "# only a comment\n"}
	for _, in := range cases {
		t.Run(strings.TrimSpace(in)+"|", func(t *testing.T) {
			_, err := ParseYAML(in)
			assert.Error(t, err)
		})
	}
}
