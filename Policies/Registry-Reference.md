# Registry policy reference

## Extension ID

```text
knepjpocdagponkonnbggpcnhnaikajg
```

## Microsoft Edge

### Force install

```text
HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionSettings\knepjpocdagponkonnbggpcnhnaikajg
```

| Name | Type | Value |
|---|---|---|
| `installation_mode` | REG_SZ | `force_installed` |
| `update_url` | REG_SZ | `https://edge.microsoft.com/extensionwebstorebase/v1/crx` |
| `toolbar_state` | REG_SZ | `force_shown` |

### Extension policy

```text
HKLM\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\knepjpocdagponkonnbggpcnhnaikajg\policy
```

| Name | Type | Value |
|---|---|---|
| `showNotifications` | REG_DWORD | `1` |
| `enableValidPageBadge` | REG_DWORD | `0` |
| `enablePageBlocking` | REG_DWORD | `1` |
| `enableCippReporting` | REG_DWORD | `0` or `1` |
| `cippServerUrl` | REG_SZ | `https://cipp.bewustcloud.nl` |
| `cippTenantId` | REG_SZ | klant tenant ID/domain |
| `customRulesUrl` | REG_SZ | leeg |
| `updateInterval` | REG_DWORD | `1` |
| `enableDebugLogging` | REG_DWORD | `0` |

### Branding

```text
HKLM\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\knepjpocdagponkonnbggpcnhnaikajg\policy\customBranding
```

| Name | Type | Value |
|---|---|---|
| `companyName` | REG_SZ | `Bewust ICT` |
| `productName` | REG_SZ | `Bewust ICT Security Check` |
| `companyURL` | REG_SZ | `https://www.bewustict.nl` |
| `supportEmail` | REG_SZ | `noc@bewustict.nl` |
| `supportUrl` | REG_SZ | `https://www.bewustict.nl` |
| `privacyPolicyUrl` | REG_SZ | `https://bewustict.nl/privacy_verklaring/` |
| `aboutUrl` | REG_SZ | `https://www.bewustict.nl` |
| `primaryColor` | REG_SZ | `#63B1BC` |
| `logoUrl` | REG_SZ | `https://bewustict.nl/wp-content/uploads/2025/10/Logo-zonder-beeldberk.svg` |

## Google Chrome

Chrome gebruikt dezelfde structuur onder:

```text
HKLM\SOFTWARE\Policies\Google\Chrome
```

De update URL voor Chrome is:

```text
https://clients2.google.com/service/update2/crx
```
