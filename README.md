# Redmine PowerShell Module

PowerShell client for Redmine REST API.

## Features

1. Projects
1. Issues
1. Files
1. Wiki
1. Users
1. Time Entries

## How to use

1. Obtain Redmine API key via *My Account -> API access key*
1. Import module: `import-module mm-redmine`
1. Initialize session: `Initialize-RedmineSession -Url 'https://redmine...' -Key '<key>'`

You can use any module function now. To get a list of available functions invoke: `Get-Command -Module mm-redmine`.

Use `$VerbosePreference = 'Continue'` on the top of the script or `-Verbose` option on any function to see detailed low level communication with Redmine.

## Prerequisites

Nothing particular is required. Works with PowerShell 3+.

## Examples

### Login

```ps1
# Login to redmine using your key: My account -> API access key
# Must have Administration -> Settings -> API -> [x] Enable REST web service
Initialize-RedmineSession -Url 'https://redmine...' -Key '<key>'
```

### Projects

```ps1

# Get all projects
Get-RedmineProject | Format-Table

# Get project by name
Get-RedmineProject -Name test
```

### Issues

```ps1

# Get single issue
Get-RedmineIssue -Id 112 -Include watchers

# Get all issues
Get-RedmineIssue

# Get project issues and show them in table
$filter = New-RedmineIssueFilter -ProjectId $project.id
$issues = Get-RedmineIssue -Filter $filter
$htAuthor = @{ N='author'; E={$_.author.name} }
$issues | Format-Table subject, $htAuthor, created_on, start_date, due_date

# Filter issues by custom field by the name 'Level'
## get custom field Level as id
$filter  = New-RedmineIssueFilter -ProjectId $p.id
$cf      = Get-RedmineIssue -Filter $filter -Limit 1 | % custom_fields
$levelId = Get-RedmineCustomFieldId $cf Level
$filter  = New-RedmineIssueFilter -ProjectId $p.id -CustomFields @{ levelId = 'Senior' }
Get-RedmineIssue -Filter $filter

# Add watcher
Add-RedmineIssueWatcher -IssueId 1124  -UserId 9

# Create issue
New-RedmineIssue -ProjectId $project.id -Subject test
```

### Files

```ps1
$u = Publish-RedmineFile $PSScriptRoot\test.ps1
Update-RedmineIssue -Id 1474 -Uploads @{ token = $u.token; filename = 'test.ps1'; content_type = "text/plain" }
```

### Wiki

```ps1
# Get all wiki pages
$res = Get-RedmineWikiPages -ProjectName test
$res | Format-Table

# Get concrete page and convert to HTML (if in markdown)
$page = Get-RedmineWikiPage -ProjectName test -PageName wiki
$page.text | ConvertFrom-Markdown | % Html

# Set wiki page
$markdown = @"
# PowerShell Test

This is created/updated from ``pwsh``.
"@
Set-RedmineWikiPage -ProjectName test -PageName test -Text $markdown -Comments "Created by pwsh"
```

### Users

```ps1
# Create user
$user = @{
    Login                      = 'test_user'
    Password                   = 'test'
    Firstname                  = 'test'
    Lastname                   = 'user'
    Mail                       = 'test_user@example.com'
    AuthenticationSourceId     = 0
    MustChangePassword         = $false
    SendInformation            = $false
    GeneratePassword           = $false
}
$user = New-RedmineUser @user

# Remove user
Remove-RedmineUser $user.id
```

### Time Entries

```ps1

# Get entires for project and user
$fu = New-RedmineUserFilter -Name test_user
$u = Get-RedmineUser -Filter $fu
$fte = New-RedmineTimeEntriesFilter -ProjectId test -UserId $u.Id
$te = Get-RedmineTimeEntries -Filter $fte
$te | Format-Table

# Create
$params = @{
   ProjectId  = 'test'
   UserId     = $u.id
   SpentOn    = '2023-11-29'
   ActivityId = 1
   Comments   = "Test"
   Hour       = 8
}
$te = New-RedmineTimeEntry @params

# Update
Update-RedmineTimeEntry -Id $te.id -Comment "some comment"

# Delete
Remove-RedmineTimeEntry -Id $te.id
```