# Architectuur

## Componenten

```text
NinjaOne
  -> draait PowerShell scripts als SYSTEM/Admin
  -> schrijft browser enterprise policies in HKLM

Microsoft Edge / Google Chrome
  -> leest ExtensionSettings
  -> force-installeert Check
  -> leest 3rdparty extension policy

Check by CyberDrain
  -> gebruikt Bewust ICT branding
  -> blokkeert verdachte/phishing loginpagina's
  -> kan optioneel alerts naar CIPP sturen

CIPP Open Source
  -> ontvangt Check alerts
  -> beheert de extensie niet
```

## Waarom registry policies?

Check ondersteunt enterprise configuratie via Chrome/Edge policies. Voor Windows betekent dit dat policies onder `HKLM\SOFTWARE\Policies` gezet kunnen worden. Dit is geschikt voor GPO, Intune, NinjaOne of andere RMM tooling.

## Edge versus Chrome

| Browser | Policy root | Update URL |
|---|---|---|
| Edge | `HKLM\SOFTWARE\Policies\Microsoft\Edge` | `https://edge.microsoft.com/extensionwebstorebase/v1/crx` |
| Chrome | `HKLM\SOFTWARE\Policies\Google\Chrome` | `https://clients2.google.com/service/update2/crx` |

## Extension ID

```text
knepjpocdagponkonnbggpcnhnaikajg
```

Dit is het extension ID dat in de bestaande Theiner ICT deployment is aangetroffen en ook wordt gebruikt voor de Edge enterprise deployment.

## Legacy Theiner cleanup

De oude Theiner configuratie stond onder:

```text
HKLM\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\knepjpocdagponkonnbggpcnhnaikajg\policy
HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionSettings\knepjpocdagponkonnbggpcnhnaikajg
```

Het install-script verwijdert eerst de oude 3rdparty policy en schrijft daarna de Bewust ICT policy terug.

## CIPP Reporting

CIPP Reporting wordt niet in CIPP zelf ingeschakeld. Het wordt als policy aan de browserextensie meegegeven.

De volgende waarden zijn opgenomen in de scripts:

```text
enableCippReporting
cippServerUrl
cippTenantId
```

Deze waarden zijn gebaseerd op aangetroffen managed policy registrywaarden. Voor productie moet CIPP Reporting nog gevalideerd worden met een echte test-alert.
