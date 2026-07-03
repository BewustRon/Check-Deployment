# Bewust ICT Security Check Deployment

Deploymentbibliotheek voor **Check by CyberDrain** met Bewust ICT white-label branding, Edge/Chrome enterprise policies en NinjaOne scripts.

> Status: v0.1 - basisstructuur en eerste scripts. Nog niet blind productie-uitrollen zonder test op 1 device.

## Doel

Deze repository moet een herbruikbare standaard worden om Check bij klanten uit te rollen:

- Oude Theiner ICT branding/policies opruimen
- Check forceren in Microsoft Edge en optioneel Google Chrome
- Bewust ICT branding toepassen
- Optioneel CIPP Reporting configureren
- Detectie en logging geschikt voor NinjaOne

## Bewust ICT branding

| Instelling | Waarde |
|---|---|
| Company name | Bewust ICT |
| Product name | Bewust ICT Security Check |
| Primary color | `#63B1BC` |
| Support email | `noc@bewustict.nl` |
| Support URL | `https://www.bewustict.nl` |
| Privacy policy URL | `https://bewustict.nl/privacy_verklaring/` |
| Logo URL | `https://bewustict.nl/wp-content/uploads/2025/10/Logo-zonder-beeldberk.svg` |
| CIPP URL | `https://cipp.bewustcloud.nl` |

## Repository structuur

```text
Branding/
  bewustict-branding.json
Docs/
  Architecture.md
  CIPP-Reporting.md
  NinjaOne.md
NinjaOne/
  Detect-BewustICT-Check.ps1
  Install-BewustICT-Check.ps1
  Uninstall-BewustICT-Check.ps1
Policies/
  Registry-Reference.md
CHANGELOG.md
README.md
```

## Eerste test

1. Pak 1 testapparaat.
2. Draai `NinjaOne/Detect-BewustICT-Check.ps1` als Administrator.
3. Draai `NinjaOne/Install-BewustICT-Check.ps1` als Administrator.
4. Sluit Edge/Chrome volledig af.
5. Open `edge://policy` en controleer of de extensie en 3rdparty policy zichtbaar zijn.
6. Controleer `edge://extensions`.

## Belangrijk

- CIPP is niet het beheerportaal van Check. De extensie wordt beheerd via browser enterprise policies.
- CIPP Reporting wordt via de Check policy ingesteld.
- CIPP Reporting keys zijn opgenomen op basis van aangetroffen policywaarden en moeten nog gevalideerd worden met een echte alert.
