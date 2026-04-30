package templates

import "embed"

//go:embed layout/*.html public/*.html admin/*.html
var FS embed.FS
