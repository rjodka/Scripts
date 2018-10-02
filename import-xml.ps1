Function Import-XMLConfig
{
    [CmdletBinding()]
    Param
    (
        #path do xml
        [Parameter(Mandatory = $true)]
        $ConfigPath
    )

    [hashtable]$Config = @{ }

    # carrega configuração
    $xmlfile = [xml]([System.IO.File]::ReadAllText($configPath))

    # Seta as informações
    $Config.server = $xmlfile.Configuration.servers.srv
    $Config.service = $xmlfile.Configuration.service.name
    $Config.log = $xmlfile.Configuration.log.path
    $Config.url = $xmlfile.Configuration.webhook.url
    $Config.plat = $xmlfile.Configuration.Status.plat
    $Config.sm = $xmlfile.Configuration.sm.url
    $Config.category = $xmlfile.Configuration.imdados.category
    $Config.company = $xmlfile.Configuration.imdados.company
    $Config.alternatecontact = $xmlfile.Configuration.imdados.alternatecontact
    $Config.assignmentgroup = $xmlfile.Configuration.imdados.assignmentgroup
    $Config.impact = $xmlfile.Configuration.imdados.impact
    $Config.configura = $xmlfile.Configuration.imdados.configura
    $Config.producttype = $xmlfile.Configuration.imdados.producttype
    $Config.symptom = $xmlfile.Configuration.imdados.symptom
    $Config.subcategory = $xmlfile.Configuration.imdados.subcategory
    $Config.urgency = $xmlfile.Configuration.imdados.urgency
    Return $Config
}