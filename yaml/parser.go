package yaml

import (
	"encoding/json"
	"github.com/icza/dyno"
	yamlParser "gopkg.in/yaml.v2"
	meta_v1_unstruct "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"log"
)

// ParseYAML parses a yaml string into a Manifest.
//
// To make things play nice we need the JSON representation of the object as the `RawObj`
// 1. UnMarshal YAML into map
// 2. Marshal map into JSON
// 3. UnMarshal JSON into the Unstructured type so we get some K8s checking
func ParseYAML(yaml string) (*Manifest, error) {
	rawYamlParsed := &map[string]interface{}{}
	err := yamlParser.Unmarshal([]byte(yaml), rawYamlParsed)
	if err != nil {
		return nil, err
	}

	rawJSON, err := json.Marshal(dyno.ConvertMapI2MapS(*rawYamlParsed))
	if err != nil {
		return nil, err
	}

	unstruct := meta_v1_unstruct.Unstructured{}
	err = unstruct.UnmarshalJSON(rawJSON)
	if err != nil {
		return nil, err
	}

	manifest := &Manifest{
		Raw: &unstruct,
	}

	// Log only the identifying metadata at DEBUG. Previously this dumped
	// the full UnstructuredContent which includes Secret data/stringData —
	// any caller running with TF_LOG=DEBUG ended up with Secret material
	// in their log archives. If you need the full payload for debugging,
	// fetch it with `kubectl get <kind>/<name> -n <namespace> -o yaml`.
	log.Printf("[DEBUG] %s parsed manifest: apiVersion=%s kind=%s namespace=%s name=%s",
		manifest, manifest.GetAPIVersion(), manifest.GetKind(), manifest.GetNamespace(), manifest.GetName())
	return manifest, nil
}
