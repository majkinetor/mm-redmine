# Redmine PowerShell Module

## How to use

1. Obtain Redmine API key via *My Account -> API access key*
1. Import module: `import-module mm-redmine`
1. Initialize session: `Initialize-RedmineSession -Url 'https://redmine...' -Key '<key>'`

You can use any module function now. To get a list of available functions invoke: `Get-Command -Module mm-redmine`.

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

### Users

```ps1
# Create user
$user = @{
    Login                      = 'test'
    Password                   = 'test'
    Firstname                  = 'test'
    Lastname                   = 'test'
    Mail                       = 'example@example.com'
    AuthenticationSourceId     = 0
    MustChangePassword         = $false
    SendInformation            = $false
    GeneratePassword           = $false
}
$user = New-RedmineUser @user

# Remove user
Remove-RedmineUser $user.id
```
