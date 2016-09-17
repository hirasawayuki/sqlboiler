{{- define "relationship_to_one_test_helper"}}
{{- $dot := .Dot -}}
{{- with .Rel}}
func test{{.LocalTable.NameGo}}ToOne{{.ForeignTable.NameGo}}_{{.Function.Name}}(t *testing.T) {
	tx := MustTx(boil.Begin())
	defer tx.Rollback()

	var foreign {{.ForeignTable.NameGo}}
	var local {{.LocalTable.NameGo}}
	{{if .ForeignKey.Nullable -}}
	local.{{.ForeignKey.Column | titleCase}}.Valid = true
	{{end}}
	{{- if .ForeignKey.ForeignColumnNullable -}}
	foreign.{{.ForeignKey.ForeignColumn | titleCase}}.Valid = true
	{{end}}

	{{if not .Function.OneToOne -}}
	if err := foreign.Insert(tx); err != nil {
		t.Fatal(err)
	}

	local.{{.Function.LocalAssignment}} = foreign.{{.Function.ForeignAssignment}}
	if err := local.Insert(tx); err != nil {
		t.Fatal(err)
	}
	{{else -}}
	if err := local.Insert(tx); err != nil {
		t.Fatal(err)
	}

	foreign.{{.Function.ForeignAssignment}} = local.{{.Function.LocalAssignment}}
	if err := foreign.Insert(tx); err != nil {
		t.Fatal(err)
	}
	{{end -}}

	check, err := local.{{.Function.Name}}(tx).One()
	if err != nil {
		t.Fatal(err)
	}

	{{if .Function.UsesBytes -}}
	if 0 != bytes.Compare(check.{{.Function.ForeignAssignment}}, foreign.{{.Function.ForeignAssignment}}) {
	{{else -}}
	if check.{{.Function.ForeignAssignment}} != foreign.{{.Function.ForeignAssignment}} {
	{{end -}}
		t.Errorf("want: %v, got %v", foreign.{{.Function.ForeignAssignment}}, check.{{.Function.ForeignAssignment}})
	}

	slice := {{.LocalTable.NameGo}}Slice{&local}
	if err = local.L.Load{{.Function.Name}}(tx, false, &slice); err != nil {
		t.Fatal(err)
	}
	if local.R.{{.Function.Name}} == nil {
		t.Error("struct should have been eager loaded")
	}

	local.R.{{.Function.Name}} = nil
	if err = local.L.Load{{.Function.Name}}(tx, true, &local); err != nil {
		t.Fatal(err)
	}
	if local.R.{{.Function.Name}} == nil {
		t.Error("struct should have been eager loaded")
	}
}

{{end -}}
{{- end -}}
{{- if .Table.IsJoinTable -}}
{{- else -}}
	{{- $dot := . -}}
	{{- range .Table.FKeys -}}
		{{- $txt := textsFromForeignKey $dot.PkgName $dot.Tables $dot.Table . -}}
{{- template "relationship_to_one_test_helper" (preserveDot $dot $txt) -}}
{{end -}}
{{- end -}}
