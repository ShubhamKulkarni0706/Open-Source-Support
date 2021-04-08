# Global Variables
$DataPath = "C:\TEMP\"
$UsgsUrl = "https://waterservices.usgs.gov"

# Sites (examples)
# https://maps.waterdata.usgs.gov/mapper/index.html
$LevlObsPeriod = 72                         # Period for observed level data to be retrieved
$RainObsPeriod = 72                         # Period for observed rainfall data to be retrieved
$USGSTidlSites = @(                         # =< Add/Remove as necessary >=
  "01392650"                                # Newark
)
$USGSLevlSites = @(                         # =< Add/Remove as necessary >=
  "01389890"                                # Dundee Dam
)
$USGSRainSites = @(                         # =< Add/Remove as necessary >=
  "405245074022401"                         # Hackensack            
  "404241074072201"                         # Newark
  "01376515"                                # Hudson River Pier 84
  "01376520"                                # Hudson River Pier 26
  "405939074084301"                         # Ridgewood
)

# Parameter codes                           # https://help.waterdata.usgs.gov/codes-and-parameters/parameters
$ParamCodes = @{
  TidElevation = '72279'
  PhysGageHeight = '00065'
  PhysPrecip = '00045'
}

# Function to get data in JSON format, convert date time to UTC and export relevant fields to Simple CSV format
function Get-Data {
  Param($SiteArray, $ParameterCd, $Period)
  ForEach ($SiteId in $SiteArray) {
    $OutFile = ($DataPath + $SiteId + "_obs_" + $Period + "hrs.csv")
    $RestUrl = $UsgsUrl + "/nwis/iv/?sites=" + $SiteId +"&format=json&period=PT" + $Period + "H&parameterCd=$parameterCd"
    $json = Invoke-WebRequest -Uri $RestUrl -UseBasicParsing | ConvertFrom-Json
    $json.value.timeseries.values.value | Select-Object datetime,value |
    ForEach-Object { 
      $_.datetime = [datetime]::Parse($_.datetime).ToUniversalTime().ToString("yyyy-MM-dd HH:mm")
      $_
    } |
    ConvertTo-CSV -NoTypeInformation |
    ForEach-Object {$_ -replace '"',''} | 
    Out-File -encoding "ASCII" $OutFile
    Write-Output $OutFile
  }
}

# Create a path for the files if it doesn't exist
New-Item -ItemType Directory -Force -Path $DataPath | Out-Null

# Call Get-Data function
Get-Data -SiteArray $USGSTidlSites -ParameterCd $ParamCodes.TidElevation -Period $LevlObsPeriod
Get-Data -SiteArray $USGSLevlSites -ParameterCd $ParamCodes.PhysGageHeight -Period $LevlObsPeriod
Get-Data -SiteArray $USGSRainSites -ParameterCd $ParamCodes.PhysPrecip -Period $RainObsPeriod

# Example REST Url
# https://waterservices.usgs.gov/nwis/iv/?sites=405939074084301&format=rdb&period=PT72H&parameterCd=00045