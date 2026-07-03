# CIPP Reporting

## Belangrijk

CIPP is niet het beheerportaal van Check. Check wordt beheerd via browser enterprise policies. CIPP kan alerts ontvangen zodra de extensie is geconfigureerd om naar CIPP te rapporteren.

## Bewust ICT CIPP URL

```text
https://cipp.bewustcloud.nl
```

## Policy waarden

De scripts gebruiken deze policywaarden onder de 3rdparty extension policy:

```text
enableCippReporting = 1
cippServerUrl = https://cipp.bewustcloud.nl
cippTenantId = <tenant-id-of-primary-domain>
```

## Tenant ID strategie

Nog te bepalen per klant. Mogelijke opties:

1. Microsoft tenant GUID
2. Primary domain, bijvoorbeeld `klant.nl`
3. Onmicrosoft domein, bijvoorbeeld `klant.onmicrosoft.com`

## Aanbevolen test

1. Kies een testtenant.
2. Configureer 1 testapparaat met:

```powershell
.\Install-BewustICT-Check.ps1 -EnableCippReporting -CippTenantId "<test-tenant-id>"
```

3. Controleer `edge://policy`.
4. Genereer een Check security event volgens de officiële testprocedure.
5. Controleer in CIPP of de alert binnenkomt.
6. Leg vast welke tenant ID-vorm correct wordt gematcht.

## Status

Nog niet als productie-klaar markeren totdat een echte alert succesvol in CIPP zichtbaar is.
