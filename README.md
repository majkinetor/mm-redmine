# mm-redmine

WIP - Redmine PowerShell module

## Login

```ps1
# Login to redmine using your key: My account -> API access key
# Must have Administration -> Settings -> API -> [x] Enable REST web service
Initialize-RedmineSession -Url 'https://redmine...' -Key '<key>'
```

## Projects

```ps1

# Get all projects
Get-RedmineProject | Format-Table

# Get project by name
Get-RedmineProject -Name hmr
```
