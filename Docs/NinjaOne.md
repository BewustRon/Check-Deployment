# NinjaOne deployment

## Scripts

| Script | Doel |
|---|---|
| `Detect-BewustICT-Check.ps1` | Controleert of de policy aanwezig en correct is |
| `Install-BewustICT-Check.ps1` | Verwijdert oude Theiner branding en configureert Bewust ICT Check |
| `Uninstall-BewustICT-Check.ps1` | Verwijdert de managed Check policies |

## Installeren op 1 testapparaat

Maak in NinjaOne een script aan:

- Name: `Install - Bewust ICT Security Check`
- Language: PowerShell
- Run as: System / Administrator
- Script: inhoud van `NinjaOne/Install-BewustICT-Check.ps1`

Run eerst zonder parameters.

```powershell
.\Install-BewustICT-Check.ps1
```

Dit configureert alleen Microsoft Edge.

## Chrome ook configureren

```powershell
.\Install-BewustICT-Check.ps1 -ConfigureChrome
```

## CIPP Reporting inschakelen

Gebruik dit pas na validatie op een testtenant.

```powershell
.\Install-BewustICT-Check.ps1 -EnableCippReporting -CippTenantId "tenant-guid-of-primary-domain"
```

De standaard CIPP URL is:

```text
https://cipp.bewustcloud.nl
```

## Detectie

Voor NinjaOne voorwaarden/remediations:

```powershell
.\Detect-BewustICT-Check.ps1
```

Exit code:

- `0` = compliant
- `1` = remediation nodig

## Verwijderen

```powershell
.\Uninstall-BewustICT-Check.ps1 -KillBrowsers
```

Chrome policies ook verwijderen:

```powershell
.\Uninstall-BewustICT-Check.ps1 -RemoveChrome -KillBrowsers
```

## Test na installatie

Op het apparaat:

1. Sluit Edge volledig af.
2. Open Edge opnieuw.
3. Ga naar `edge://policy`.
4. Klik `Reload policies`.
5. Controleer `ExtensionSettings` en `3rdparty` policy.
6. Ga naar `edge://extensions`.
7. Controleer of de extensie managed/force-installed is.
