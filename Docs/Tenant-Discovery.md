# Tenant Discovery

## Doel

De deployment moet zonder klant-specifieke parameters kunnen draaien. Voor CIPP Reporting is waarschijnlijk een tenant identifier nodig. Dit document beschrijft de gekozen discovery-aanpak.

## Huidige aanpak

Het vNext install-script probeert de tenant automatisch te bepalen via:

```powershell
dsregcmd.exe /status
```

Daaruit worden deze velden gelezen:

```text
TenantId
TenantName
```

De voorkeur is:

1. `TenantId` GUID
2. `TenantName`
3. Leeg laten en waarschuwing loggen

## Waarom dsregcmd?

Voordelen:

- Geen Graph app registration nodig.
- Geen interactieve login nodig.
- Werkt lokaal op Entra Joined en Hybrid Joined devices.
- Geschikt voor NinjaOne/SYSTEM context.

## Beperkingen

- Op pure workgroup devices zonder Entra registration is er mogelijk geen TenantId.
- Op klassieke servers/DC's is er meestal geen tenantcontext.
- We moeten nog valideren of CIPP liever Tenant GUID, primary domain of onmicrosoft domain verwacht.

## Testprocedure

Op een test-pc:

```powershell
NinjaOne\Install-BewustICT-Check-vNext.ps1 -EnableCippReporting
```

Daarna controleren:

```powershell
reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\knepjpocdagponkonnbggpcnhnaikajg\policy"
```

Controleer de waarde:

```text
cippTenantId
```

## Open punt

CIPP tenant matching is nog niet gevalideerd. Dit blijft open tot een echte Check alert succesvol in CIPP binnenkomt en aan de juiste tenant gekoppeld wordt.
