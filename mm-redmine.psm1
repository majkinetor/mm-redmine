# v0.1

enum UserStatus
{
    anonymous   = 0
    active      = 1
    registered  = 2
    locked      = 3
}

<#
enum IssueOperations
{
    is        = '='
    isnot     = '!='
    any       = '*'
    contains  = '=~'
    ge        = '>='
    le        = '<='
    gt        = '>'
    lt        = '<'
}
#>

# https://www.redmine.org/projects/redmine/wiki/Rest_Users#DELETE
function Remove-RedmineUser( [int] $UserId ) {
    $params = @{
        Method = 'Delete'
        Endpoint = "users/$UserId.json"
    }
    $res = Send-Request $params
    $res
}

# https://www.redmine.org/projects/redmine/wiki/Rest_Users#POST
function New-RedmineUser {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Login,

        [string] $Password,

        [Parameter(Mandatory=$true)]
        [string] $Firstname,

        [Parameter(Mandatory=$true)]
        [string] $Lastname,

        [Parameter(Mandatory=$true)]
        [string] $Mail,

        [int] $AuthenticationSourceId = 0,
        [switch] $MustChangePassword,
        [switch] $SendInformation,
        [switch] $GeneratePassword
    )

    $user = @{
        login = $Login
        firstname = $Firstname
        lastname = $Lastname
        mail = $Mail
        password = $Password
        auth_source_id = $AuthenticationSourceId
    }
    if ($MustChangePassword) { $user.must_change_passwd = $true }
    if ($SendInformation)    { $user.send_information = $true }
    if ($GeneratePassword)   { $user.generate_password = $true }

    $params = @{
        Method = 'Post'
        Endpoint = "users.json"
        Body  = @{ user = $user }
    }
    $res = Send-Request $params
    $res.user
}

function Initialize-RedmineSession {
    param(
        [string] $Url,
        [string] $Key
    )
    $script:Redmine = @{ Url = $Url; Key = $Key }
}

function Add-RedmineIssueWatcher([int]$IssueId, [string[]] $UserId) {
    $params = @{
        Method = 'Post'
        Endpoint = "issues/${IssueId}/watchers.json"
        Body  = @{ user_id = $UserId }
    }
    $res = Send-Request $params
}

# https://redmine.org/projects/redmine/wiki/Rest_Memberships
function Get-RedmineMembership {
    param(
        [string] $ProjectId
    )

    $params = @{
        Endpoint = "projects/${ProjectId}/memberships.json"
    }
    $res = Send-Request $params
    $res.memberships
}

# https://redmine.org/projects/redmine/wiki/Rest_Issues
function New-RedmineIssueRelation {
    param(
        [int] $IssueId,
        [int] $IssueToId,
        [ValidateSet('relates', 'duplicates', 'duplicated', 'blocks', 'blocked', 'precedes', 'follows', 'copied_to', 'copied_from')]
        [string] $RelationType = 'relates'
    )

    $relation = @{
        issue_to_id   = $IssueToId
        relation_type = $RelationType
    }

    $params = @{
        Method   = 'POST'
        Endpoint = "issues/${IssueId}/relations.json"
        Body = @{ relation = $relation }
    }
    $res = Send-Request $params
    $res.relation
}

# https://redmine.org/projects/redmine/wiki/Rest_Issues
function New-RedmineIssue {
    param(
        [Parameter(Mandatory = $true)]
        [int]    $ProjectId,
        [Parameter(Mandatory = $true)]
        [string] $Subject,
        [int]    $TrackerId,
        [string] $Description,
        [int]    $StatusId,
        [int]    $PriorityId,
        [int]    $CategoryId,
        [int]    $AssigneeId,
        [int[]]  $WatcherId,
        [array]  $Uploads,
        [HashTable] $CustomFields
    )

    $issue = @{ project_id = $ProjectId;  subject = $Subject }
    if ($Description){ $issue.description      = $Description }
    if ($TrackerId)  { $issue.tracker_id       = $TrackerId}
    if ($StatusId)   { $issue.status_id        = $StatusId }
    if ($PriorityId) { $issue.priority_id      = $PriorityId }
    if ($CategoryId) { $issue.category_id      = $CategoryId }
    if ($AssigneeId) { $issue.assigned_to_id   = $AssigneeId }
    if ($WatcherId)  { $issue.watcher_user_ids = $WatcherId }
    if ($Uploads)    { $issue.uploads          = $Uploads }
    if ($CustomFields) {
        $issue.custom_fields = @()
        foreach($element in $CustomFields.GetEnumerator()){
            $issue.custom_fields +=  @{ id = $element.Key ; value = $element.value;  }
        }
    }

    $params = @{
        Method   = 'POST'
        Endpoint = "issues.json"
        Body = @{ issue = $issue }
    }
    $res = Send-Request $params
    $res.issue
}

# https://redmine.org/projects/redmine/wiki/Rest_Issues#Updating-an-issue
function Update-RedmineIssue {
    param(
        [Parameter(Mandatory = $true)]
        [int]    $Id,
        [int]    $ProjectId,
        [int]    $TrackerId,
        [string] $Subject,
        [string] $Description,
        [int]    $StatusId,
        [int]    $PriorityId,
        [int]    $CategoryId,
        [int]    $AssigneeId,
        [int[]]  $WatcherId,
        [string] $Notes,
        [switch] $PrivateNotes,
        [array]  $Uploads,
        [HashTable] $CustomFields
    )
    $issue = @{}

    if ($ProjectId)    { $issue.project_id       = $ProjectId }
    if ($TrackerId)    { $issue.tracker_id       = $TrackerId }
    if ($Subject)      { $issue.subject          = $Subject }
    if ($Description)  { $issue.description      = $Description }
    if ($StatusId)     { $issue.status_id        = $StatusId }
    if ($PriorityId)   { $issue.priority_id      = $PriorityId }
    if ($CategoryId)   { $issue.category_id      = $CategoryId }
    if ($AssigneeId)   { $issue.assigned_to_id   = $AssigneeId }
    if ($WatcherId)    { $issue.watcher_user_ids = $WatcherId }
    if ($Notes)        { $issue.notes            = $Notes }
    if ($PrivateNotes) { $issue.private_notes    = $true }
    if ($Uploads)      { $issue.uploads          = $Uploads }
    if ($CustomFields) {
        $issue.custom_fields = @()
        foreach($element in $CustomFields.GetEnumerator()){
            $issue.custom_fields +=  @{ id = $element.Key ; value = $element.value;  }
        }
    }

    $params = @{
        Method   = 'PUT'
        Endpoint = "issues/$Id.json"
        Body = @{ issue = $issue }
    }
    $res = Send-Request $params
}

# https://redmine.org/projects/redmine/wiki/Rest_Issues#Deleting-an-issue
function Remove-RedmineIssue {
    param(
        [Parameter(Mandatory = $true)]
        [int] $Id
    )

    $params = @{
        Method   = 'DELETE'
        Endpoint = "issues/$Id.json"
    }
    $res = Send-Request $params
    $res
}

# https://redmine.org/projects/redmine/wiki/Rest_api#Attaching-files
function Publish-RedmineFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,
        [string] $FileName
    )

    if (!(Test-Path $FilePath)) { throw "File doesn't exist: $FilePath" }
    if (!$FileName) { $FileName = Split-Path -Leaf $FilePath }

    $params = @{
        Method   = 'POST'
        Endpoint = "uploads.json?filename=/$FileName.json"
        ContentType = "application/octet-stream"
        InFile      = $FilePath
    }

    $res = Send-Request $params
    $res.upload
}

# https://redmine.org/projects/redmine/wiki/Rest_Users
function Get-RedmineUser {
    param(
        [int] $Offset = 0,
        [int] $Limit = 100,
        [PSCustomObject] $Filter,
        [int] $Id
    )
    if ($Filter) { if ($Filter.PSObject.TypeNames[0] -ne 'UserFilter') { throw 'Invalid filter type, it should be UserFilter' } }

    $pFilter = if ($Filter) { "&$($Filter.Query)" }
    $params = @{
        Endpoint = if ($Id) { "users/$Id.json"} else {  "users.json?offset=${Offset}&limit=${Limit}${pFilter}" }
    }
    $res = Send-Request $params
    $res.users
}

function Get-RedmineCustomFieldId( [Object[]]$CustomFields, [string] $Name) {
    $CustomFields | ? name -eq $Name | % id
}

# https://redmine.org/projects/redmine/wiki/Rest_Issues
function Get-RedmineIssue {
    param(
       [string]  $SortColumn,
       [switch]  $SortDesc,
       [int]     $Offset = 0,
       [int]     $Limit = 100,
       [ValidateSet('children', 'attachments', 'relations', 'changesets', 'journals', 'watchers', 'allowed_statuses')]
       [string[]]  $Include,
       [PSCustomObject] $Filter,
       [int]     $Id
    )

    if ($Filter) { if ($Filter.PSObject.TypeNames[0] -ne 'IssueFilter') { throw 'Invalid filter type, it should be IssueFilter' } }

    $pFilter   = if ($Filter) { "&$($Filter.Query)" }
    $sortOrder = if ($SortDesc) { ":desc" }
    $sort      = if ($SortColumn) { "&sort={0}{1}" -f $SortColumn, $sortOrder }
    $pInclude  = if ($Include) { "&include={0}" -f ($Include -join ',') }
    if ($Id -and $Include) { $pInclude = $pInclude.Replace('&', '?') }

    $params = @{
        Endpoint = if ($Id) { "issues/$Id.json${pInclude}"} else { "issues.json?offset=${Offset}&limit=${Limit}${pInclude}${pFilter}" }
    }
    $res = Send-Request $params
    if ($Id) { $res.issue } else { $res.issues }
}
function Get-RedmineTracker ($Name) {
    $params = @{
        EndPoint = "trackers.json"
    }
    $res = Send-Request $params
    if ($Name) { $res.trackers | ? name -eq $Name }
    else { $res.trackers }
}

# https://www.redmine.org/projects/redmine/wiki/Rest_Projects
function Get-RedmineProject {
    param(
        [string] $Name
    )

    $params = @{ Endpoint = 'projects'}
    $params.Endpoint += if ($Name) { "/$Name.json" } else { '.json' }
    $params.Endpoint += '?include=trackers,issue_categories,enabled_modules,time_entry_activities'
    $res = Send-Request $params
    if ($Name) { $res.project } else { $res.projects }
}

# https://www.redmine.org/projects/redmine/wiki/Rest_Users
function New-RedmineUserFilter {
    [CmdletBinding()]
    param(
        [UserStatus] $Status,
        [string]     $Name,
        [int]        $GroupId
    )

    $res = @{}
    if ($Status)  { $res.status = [int] $Status }
    if ($Name)    { $res.name = $Name }
    if ($GroupId) { $res.group_id = $GroupId }

    foreach ($element in $res.GetEnumerator()) {
        $query += '{0}={1}' -f $element.Key, [uri]::EscapeDataString( $element.Value )
    }
    $res.Query = $query -join '&'

    $o = [PSCustomObject]$res
    $o.psobject.TypeNames.Insert(0, "UserFilter")
    $o
}

# https://www.redmine.org/projects/redmine/wiki/Rest_Issues
function New-RedmineIssueFilter {
    [CmdletBinding()]
    param(
        [int[]]  $IssueId,
        [int]    $ProjectId,
        [int]    $SubprojectId,
        [int]    $TrackerId,
        [ValidateSet('open', 'closed', '*')]
        [string] $StatusId,
        [int]    $AssignedToId,
        [string] $ParentId,
        [HashTable] $CustomFields
    )

    $res = @{}
    if ($IssueId)      { $res.issue_id       = $IssueId -join ',' }
    if ($ProjectId)    { $res.project_id     = $ProjectId }
    if ($SubprojectId) { $res.subproject_id  = $SubprojectId }
    if ($TrackerId)    { $res.tracker_id     = $TrackerId }
    if ($StatusId)     { $res.status_id      = $StatusId }
    if ($AssignedToId) { $res.assigned_to_id = $AssignedToId }
    if ($ParentId)     { $res.parent_id      = $ParentId }

    $query = @()
    foreach ($element in $res.GetEnumerator()) {
        $query += '{0}={1}' -f $element.Key, [uri]::EscapeDataString( $element.Value )
    }
    if ($CustomFields) {
        foreach ($element in $CustomFields.GetEnumerator()) {
            $query += 'cf_{0}={1}' -f $element.Key, [uri]::EscapeDataString( $element.Value )
        }
    }

    $res.Query = $query -join '&'

    $o = [PSCustomObject]$res
    $o.psobject.TypeNames.Insert(0, "IssueFilter")
    $o
}

# https://redmine.org/projects/redmine/wiki/Rest_WikiPages#Getting-the-pages-list-of-a-wiki
function Get-RedmineWikiPages {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectName
    )

    $params = @{
        EndPoint = "projects/$ProjectName/wiki/index.json"
    }
    $res = Send-Request $params
    $res.wiki_pages
}

# https://redmine.org/projects/redmine/wiki/Rest_WikiPages#Getting-a-wiki-page
function Get-RedmineWikiPage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,
        [Parameter(Mandatory = $true)]
        [string] $PageName,
        [int] $Version
    )

    $endPoint = "projects/$ProjectName/wiki/$PageName"
    $params = @{
        EndPoint = if ($Version) { "$endpoint/$Version.json" } else { "$endpoint.json" }
    }
    $res = Send-Request $params
    $res.wiki_page
}

# https://redmine.org/projects/redmine/wiki/Rest_WikiPages#Creating-or-updating-a-wiki-page
function Set-RedmineWikiPage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,
        [Parameter(Mandatory = $true)]
        [string] $PageName,
        [Parameter(Mandatory = $true)]
        [string] $Text,
        [string] $Comments,
        [int] $Version,
        [array] $Uploads
    )

    $page = @{ text = $Text }
    if ($Version)  { $page.version  = $Version }
    if ($Comments) { $page.comments = $Comments }
    if ($Uploads)  { $page.uploads  = $Uploads }

    $params = @{
        Method   = "PUT"
        EndPoint = "projects/$ProjectName/wiki/$PageName.json"
        Body     = @{ wiki_page = $page }
    }
    $res = Send-Request $params
    $res.wiki_page
}

# https://redmine.org/projects/redmine/wiki/Rest_WikiPages#Deleting-a-wiki-page
function Remove-RedmineWikiPage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,
        [Parameter(Mandatory = $true)]
        [string] $PageName
    )

    $params = @{
        Method = "DELETE"
        EndPoint = "projects/$ProjectName/wiki/$PageName"
    }
    $res = Send-Request $params
}

# https://redmine.org/projects/redmine/wiki/Rest_TimeEntries
function Get-RedmineTimeEntries {
    param(
        [int] $Offset = 0,
        [int] $Limit = 100,
        [PSCustomObject] $Filter,
        [int] $Id
    )

    $pFilter = if ($Filter) { "&$($Filter.Query)" }
    $params = @{
        Endpoint = if ($Id) { "time_entries/$Id.json"} else { "time_entries.json?offset=${Offset}&limit=${Limit}${pFilter}" }
    }
    $res = Send-Request $params
    if ($Id) { $res.time_entry  } else { $res.time_entries }
}

# https://redmine.org/projects/redmine/wiki/Rest_Enumerations#enumerationstime_entry_activitiesformat
function Get-RedmineTimeEntryActivities {
    $params = @{
        Endpoint = "enumerations/time_entry_activities.json"
    }
    $res = Send-Request $params
    $res.time_entry_activities
}

# https://redmine.org/projects/redmine/wiki/Rest_Enumerations#Enumerations
function Get-RedmineIssuePriorities {
    $params = @{
        Endpoint = "enumerations/issue_priorities.json"
    }
    $res = Send-Request $params
    $res.issue_priorities
}

function New-RedmineTimeEntriesFilter {
    param(
        [string] $ProjectId,
        [int] $UserId,
        [DateTime] $From,
        [DateTime] $To,
        [int] $ActivityId,
        [string] $Comments,
        [decimal] $Hours
    )

    $res = @{}
    if ($UserId)     { $res.user_id    = $UserId }
    if ($ProjectId)  { $res.project_id = $ProjectId }
    if ($From)       { $res.from = $From.ToString('yyyy-MM-dd') }
    if ($To)         { $res.to = $To.ToString('yyyy-MM-dd') }
    if ($ActivityId) { $res.activity_id = $ActivityId }
    if ($Comments)   { $res.comments = $Comments }
    if ($Hours)      { $res.hours = $Hours }

    $query = @()
    foreach ($element in $res.GetEnumerator()) {
        $query += '{0}={1}' -f $element.Key, [uri]::EscapeDataString( $element.Value )
    }

    $res.Query = $query -join '&'

    $o = [PSCustomObject]$res
    $o.psobject.TypeNames.Insert(0, "TimeEntriesFilter")
    $o
}

#https://redmine.org/projects/redmine/wiki/Rest_TimeEntries#Deleting-a-time-entry
function Remove-RedmineTimeEntry ([int] $Id) {
    $params = @{
        Method = 'Delete'
        Endpoint = "time_entries/$Id.json"
    }
    $res = Send-Request $params
    $res
}

#https://redmine.org/projects/redmine/wiki/Rest_TimeEntries#Updating-a-time-entry
function Update-RedmineTimeEntry {
    param(
        [int] $Id,
        [string] $ProjectId,
        [int] $IssueId,
        [int] $UserId,
        [DateTime] $SpentOn,
        [int] $ActivityId,
        [string] $Comments,
        [decimal] $Hours
    )

    $te = @{}
    if ($IssueId)    { $te.issue_id = $IssueId }
    if ($UserId)     { $te.user_id = $UserId }
    if ($ProjectId)  { $te.project_id = $ProjectId }
    if ($SpentOn)    { $te.spent_on = $SpentOn.ToString('yyyy-MM-dd') }
    if ($ActivityId) { $te.activity_id = $ActivityId }
    if ($Comments)   { $te.comments = $Comments }
    if ($Hours)      { $te.hours = $Hours }

    $params = @{
        Method = "Put"
        Endpoint = "time_entries/$Id.json"
        Body  = @{ time_entry = $te }
    }
    $res = Send-Request $params
    $res
}

# https://redmine.org/projects/redmine/wiki/Rest_TimeEntries#Creating-a-time-entry
function New-RedmineTimeEntry {
    param(
        [string] $ProjectId,
        [int] $IssueId,
        [int] $UserId,
        [DateTime] $SpentOn,
        [int] $ActivityId,
        [string] $Comments,
        [int] $Hours
    )

    $te = @{ project_id = 8 }
    if ($IssueId)    { $te.issue_id = $IssueId }
    if ($ProjectId)  { $te.project_id = $ProjectId }
    if ($UserId)     { $te.user_id = $UserId }
    if ($SpentOn)    { $te.spent_on = $SpentOn.ToString('yyyy-MM-dd') }
    if ($ActivityId) { $te.activity_id = $ActivityId }
    if ($Comments)   { $te.comments = $Comments }
    if ($Hours)      { $te.hours = $Hours }

    $params = @{
        Method = "post"
        Endpoint = "time_entries.json"
        Body  = @{ time_entry = $te }
    }
    $res = Send-Request $params
    $res
}

# Any Invoke-RestMethod parameters are provided as HashTable except Endpoint which is removed
function send-request( [HashTable] $Params ) {
    $p = $Params.Clone()
    if (!$p.Method)      { $p.Method = 'Get' }
    if (!$p.Uri)         { $p.Uri = '{0}/{1}' -f $Redmine.Url, $p.EndPoint }
    if (!$p.ContentType) { $p.ContentType = 'application/json; charset=utf-8' }
    if (!$p.Headers)     { $p.Headers = @{} }
    if ($p.Body)         { $p.Body = $p.Body | ConvertTo-Json -Depth 100 }

    $p.Headers."X-Redmine-API-Key" = $Redmine.Key
    $p.Remove('EndPoint')

    ($p | ConvertTo-Json -Depth 100).Replace('\"', '"').Replace('\r\n', '') | Write-Verbose
    Invoke-RestMethod @p
}

# $pre = Get-ChildItem Function:\*
# Get-ChildItem "$PSScriptRoot\*.ps1" | ? { $_.Name -cmatch '^[A-Z]+' } | % { . $_  }
# $post = Get-ChildItem Function:\*
# $funcs = Compare-Object $pre $post | Select-Object -Expand InputObject | Select-Object -Expand Name
# $funcs | ? { $_ -cmatch '^[A-Z]+'} | % { Export-ModuleMember -Function $_ }

# Export-ModuleMember -Alias *
