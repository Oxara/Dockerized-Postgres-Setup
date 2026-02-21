# Keycloak Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **Keycloak 26** (OAuth2/OIDC Identity Provider) + **PostgreSQL** kurulumu.

## 📁 Klasör Yapısı

```
keycloak/
└── environments/
    ├── dev/
    │   ├── docker-compose.yml
    │   └── .env
    ├── test/
    │   ├── docker-compose.yml
    │   └── .env
    └── prod/
        ├── docker-compose.yml
        └── .env
```

> Servis `.\manage.ps1` ile proje kök dizininden yönetilir. Yönetim komutları için [ana README](../README.md)'e bakın.

> Her ortam kendi PostgreSQL sidecar'ını içerir — Keycloak realm/user/client konfigürasyonu bu DB'de saklanır.

## ✨ Özellikler

- ✅ **Keycloak 26**: En güncel sürüm, OAuth2, OIDC, SAML desteği
- ✅ **PostgreSQL Sidecar**: Her ortam için ayrı, izole Keycloak DB
- ✅ **Dev Modu**: HTTP ile hızlı geliştirme (dev/test)
- ✅ **Production Modu**: Hardened `start` komutu (prod)
- ✅ **Health Checks**: DB hazır olana kadar Keycloak başlamaz
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

```powershell
# .env.example dosyasından .env oluştur
Copy-Item keycloak\environments\dev\.env.example keycloak\environments\dev\.env

# Şifreleri düzenle
notepad keycloak\environments\dev\.env
```

### 2️⃣ Başlatma

```powershell
# manage.ps1 ile (önerilen)
Set-Location C:\Projects\Docker-Service-Stack
.\manage.ps1 start dev keycloak

# veya doğrudan docker-compose ile
Set-Location keycloak\environments\dev
docker-compose -p keycloak_dev up -d
```

> ⚠️ Keycloak ilk başlamada ~60 saniye sürebilir (JVM warm-up + DB migration).

### 3️⃣ Erişim

| Ortam | Keycloak `→8080` | Admin UI | OIDC Discovery |
|-------|-----------------|----------|-----------------|
| **Dev** | http://localhost:8080 | http://localhost:8080/admin | http://localhost:8080/realms/master/.well-known/openid-configuration |
| **Test** | http://localhost:8180 | http://localhost:8180/admin | http://localhost:8180/realms/master/.well-known/openid-configuration |
| **Prod** | http://localhost:8280 | http://localhost:8280/admin | http://localhost:8280/realms/master/.well-known/openid-configuration |

**Admin Giriş Bilgileri:**
- Username: `.env` dosyasındaki `KEYCLOAK_ADMIN`
- Password: `.env` dosyasındaki `KEYCLOAK_ADMIN_PASSWORD`

### 4️⃣ İlk Yapılandırma

1. Admin Console'a giriş yapın: http://localhost:8080/admin
2. Sol üstten yeni bir **Realm** oluşturun (örn: `myapp-dev`)
3. **Clients** menüsünden yeni client ekleyin (örn: `myapp-api`)
4. **Users** menüsünden test kullanıcısı oluşturun

### 5️⃣ Durdurma

```powershell
.\manage.ps1 stop dev keycloak
```

##  Yapılandırma

### .env Değişkenleri

| Değişken | Açıklama | Varsayılan (Dev) |
|----------|----------|-----------------|
| `KC_DB_USER` | Keycloak DB kullanıcısı | `keycloak_dev_user` |
| `KC_DB_PASSWORD` | Keycloak DB şifresi | `keycloak_dev_password` |
| `KC_DB_NAME` | Keycloak veritabanı adı | `keycloak_dev_db` |
| `KEYCLOAK_ADMIN` | Admin kullanıcı adı | `admin` |
| `KEYCLOAK_ADMIN_PASSWORD` | Admin şifresi | `keycloak_dev_admin_password` |
| `KEYCLOAK_PORT` | Keycloak HTTP portu | `8080` |
| `KC_HOSTNAME` | (Prod) Keycloak hostname | `localhost` |

## 💻 .NET Core Kullanım Örnekleri

### NuGet Paketleri

```powershell
# JWT Bearer kimlik doğrulama
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer

# OIDC client (Blazor / MVC için)
dotnet add package Microsoft.AspNetCore.Authentication.OpenIdConnect
```

### ASP.NET Core API - JWT Doğrulama

```csharp
// Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = "http://localhost:8080/realms/myapp-dev";
        options.Audience  = "myapp-api";       // Keycloak'ta tanımlı client ID
        options.RequireHttpsMetadata = false;  // Dev ortamı için (prod'da true!)

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true
        };
    });

builder.Services.AddAuthorization();

// ...
app.UseAuthentication();
app.UseAuthorization();
```

```csharp
// Controllers/ProductsController.cs
[ApiController]
[Route("api/[controller]")]
[Authorize]                            // JWT gerektirir
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll() => Ok(new[] { "Product1", "Product2" });

    [HttpPost]
    [Authorize(Roles = "admin")]       // Keycloak realm rolü gerektirir
    public IActionResult Create([FromBody] object product) => Ok();

    [HttpGet("me")]
    public IActionResult GetCurrentUser()
    {
        var userId   = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var email    = User.FindFirst(ClaimTypes.Email)?.Value;
        var roles    = User.FindAll(ClaimTypes.Role).Select(c => c.Value);
        return Ok(new { userId, email, roles });
    }
}
```

### Token Alma (HttpClient)

```csharp
public class KeycloakTokenService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _config;

    public KeycloakTokenService(HttpClient httpClient, IConfiguration config)
    {
        _httpClient = httpClient;
        _config = config;
    }

    public async Task<string> GetTokenAsync(string username, string password)
    {
        var realm    = _config["Keycloak:Realm"]!;      // myapp-dev
        var clientId = _config["Keycloak:ClientId"]!;   // myapp-api
        var baseUrl  = _config["Keycloak:BaseUrl"]!;    // http://localhost:8080

        var tokenUrl = $"{baseUrl}/realms/{realm}/protocol/openid-connect/token";

        var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "password",
            ["client_id"]  = clientId,
            ["username"]   = username,
            ["password"]   = password
        });

        var response = await _httpClient.PostAsync(tokenUrl, content);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("access_token").GetString()!;
    }

    public async Task<string> GetClientCredentialsTokenAsync()
    {
        var realm        = _config["Keycloak:Realm"]!;
        var clientId     = _config["Keycloak:ClientId"]!;
        var clientSecret = _config["Keycloak:ClientSecret"]!;
        var baseUrl      = _config["Keycloak:BaseUrl"]!;

        var tokenUrl = $"{baseUrl}/realms/{realm}/protocol/openid-connect/token";

        var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"]    = "client_credentials",
            ["client_id"]     = clientId,
            ["client_secret"] = clientSecret
        });

        var response = await _httpClient.PostAsync(tokenUrl, content);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("access_token").GetString()!;
    }
}
```

### appsettings.json Yapılandırması

```json
{
  "Keycloak": {
    "BaseUrl": "http://localhost:8080",
    "Realm": "myapp-dev",
    "ClientId": "myapp-api",
    "ClientSecret": "your-client-secret-here"
  },
  "Authentication": {
    "Authority": "http://localhost:8080/realms/myapp-dev",
    "Audience": "myapp-api"
  }
}
```

### Keycloak Admin API - Realm Yönetimi

```csharp
public class KeycloakAdminService
{
    private readonly HttpClient _httpClient;

    private async Task<string> GetAdminTokenAsync()
    {
        var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "password",
            ["client_id"]  = "admin-cli",
            ["username"]   = "admin",
            ["password"]   = "keycloak_dev_admin_password"
        });

        var response = await _httpClient.PostAsync(
            "http://localhost:8080/realms/master/protocol/openid-connect/token",
            content);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("access_token").GetString()!;
    }

    public async Task<List<JsonElement>> GetUsersAsync(string realm)
    {
        var token = await GetAdminTokenAsync();
        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await _httpClient.GetAsync(
            $"http://localhost:8080/admin/realms/{realm}/users");

        return await response.Content.ReadFromJsonAsync<List<JsonElement>>()
               ?? new List<JsonElement>();
    }
}
```

### Blazor Server OIDC Entegrasyonu

```csharp
// Program.cs
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme          = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie()
.AddOpenIdConnect(options =>
{
    options.Authority            = "http://localhost:8080/realms/myapp-dev";
    options.ClientId             = "blazor-app";
    options.ClientSecret         = "your-client-secret";
    options.ResponseType         = "code";
    options.SaveTokens           = true;
    options.GetClaimsFromUserInfoEndpoint = true;
    options.RequireHttpsMetadata = false;   // Dev ortamı için

    options.Scope.Add("openid");
    options.Scope.Add("profile");
    options.Scope.Add("email");
    options.Scope.Add("roles");
});
```

## 🎭 Keycloak Kavramları

| Kavram | Açıklama |
|--------|----------|
| **Realm** | İzole kimlik yönetimi alanı (her uygulama için ayrı realm önerilir) |
| **Client** | Keycloak ile entegre olan uygulama (API, Web, Mobile) |
| **User** | Kimlik doğrulama yapacak son kullanıcı |
| **Role** | Yetki tanımı (realm-level veya client-level) |
| **Group** | Kullanıcıları gruplama ve toplu rol atama |
| **Identity Provider** | Harici login (Google, GitHub, LDAP, vb.) |

## 🔍 Sorun Giderme

### Keycloak Başlamıyor

```powershell
# Logları kontrol et (uzun sürebilir - 60+ saniye bekle)
.\manage.ps1 logs dev keycloak

# DB bağlantısı hatası ise keycloak_db önce hazır olmalı
docker ps | findstr keycloak_db
```

### "invalid_client" Hatası

```
Keycloak client'ı confidential ise client secret eksik olabilir.
Admin Console → Clients → Credentials → Secret
```

### Token'da Roller Görünmüyor

Keycloak'ta `Client Scopes` altında `roles` scope'unun mapper'ını kontrol edin:
- `realm roles` mapper → `Add to access token: ON`

### CORS Hatası (Development)

```csharp
// Program.cs - Dev için CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});
```

## 🔒 Güvenlik Notları

### Development/Test
- `KC_HOSTNAME_STRICT=false` HTTP bağlantılara izin verir
- `start-dev` modu — production'da kullanmayın!

### Production
- `start` komutunu kullanın (HTTPS ve certificate doğrulaması aktif)
- `KC_HOSTNAME` gerçek domain adı ile ayarlayın
- Admin şifresini güçlü yapın (min 20 karakter)
- Realm bazlı brute force protection aktifleştirin
- SSL/TLS termination için reverse proxy (nginx/traefik) önüne koyun

## ✅ Production Kontrol Listesi

- [ ] Tüm şifreler (DB + admin) güçlü değerlerle güncellendi mi?
- [ ] `KC_HOSTNAME` gerçek domain adresi ile ayarlandı mı?
- [ ] HTTPS / reverse proxy yapılandırıldı mı?
- [ ] Brute force protection aktifleştirildi mi?
- [ ] Session timeout değerleri ayarlandı mı?
- [ ] Realm export ile backup alındı mı?

## 🎯 Sonraki Adımlar

1. **Realm Konfigürasyonu**: Uygulama için özel realm oluşturun
2. **Client Setup**: API ve frontend için client yapılandırın
3. **Social Login**: Google, GitHub entegrasyonu ekleyin
4. **LDAP/AD**: Kurumsal kullanıcı dizini bağlantısı
5. **MFA**: İki faktörlü kimlik doğrulama aktifleştirin
6. **Realm Export**: Konfigürasyonu versiyon kontrolüne alın

---

**Hazırlayan**: Docker Keycloak Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Ana dokümantasyon: [README.md](README.md)  
🔐 Keycloak Detayları: [README-Keycloak.md](README-Keycloak.md)  
📘 PostgreSQL Detayları: [README-PostgreSQL.md](README-PostgreSQL.md)  
🔴 MSSQL Detayları: [README-MSSQL.md](README-MSSQL.md)  
📕 Redis Detayları: [README-Redis.md](README-Redis.md)  
📙 RabbitMQ Detayları: [README-RabbitMQ.md](README-RabbitMQ.md)  
📗 Elasticsearch Detayları: [README-Elasticsearch.md](README-Elasticsearch.md)  
🍃 MongoDB Detayları: [README-MongoDB.md](README-MongoDB.md)  
📊 Monitoring Detayları: [README-Monitoring.md](README-Monitoring.md)  
📋 Seq Detayları: [README-Seq.md](README-Seq.md)  
📧 MailHog Detayları: [README-MailHog.md](README-MailHog.md)

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
