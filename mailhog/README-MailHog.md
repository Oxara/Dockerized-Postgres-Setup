# MailHog Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **MailHog** (Fake SMTP Server) kurulumu. Geliştirme ortamında e-posta gönderimlerini yakalamak ve test etmek için tasarlanmıştır.

## 📁 Klasör Yapısı

```
mailhog/
├── environments/
│   ├── dev/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── test/
│   │   ├── docker-compose.yml
│   │   └── .env
│   └── prod/
│       ├── docker-compose.yml
│       └── .env
└── README-MailHog.md
```

### 🔍 Klasör Yapısı Açıklaması

- **`environments/dev/`** - Development ortamı (SMTP: 1025, Web UI: 8025)
- **`environments/test/`** - Test ortamı (SMTP: 1026, Web UI: 8026)
- **`environments/prod/`** - Prod benzeri ortam (SMTP: 1027, Web UI: 8027)

> ⚠️ **Önemli**: MailHog **gerçek e-posta göndermez**. Tüm e-postalar yakalanır ve Web UI'da görüntülenir. Sadece geliştirme ve test amaçlıdır.

## ✨ Özellikler

- ✅ **SMTP Trap**: Tüm giden e-postalar yakalanır, gerçek alıcılara ulaşmaz
- ✅ **Web UI**: Yakalanan e-postaları tarayıcıda görüntüle
- ✅ **REST API**: E-postaları programatik olarak sorgula ve sil
- ✅ **HTML & Text**: E-posta içeriğini HTML ve plain-text olarak görüntüle
- ✅ **Attachment Desteği**: Ekli dosyaları da yakalar
- ✅ **Hızlı Başlatma**: Volume gerektirmez, anında hazır
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

```powershell
Copy-Item mailhog\environments\dev\.env.example mailhog\environments\dev\.env
```

### 2️⃣ Başlatma

```powershell
.\manage.ps1 start dev mailhog
```

### 3️⃣ Erişim

| Ortam | SMTP `→1025` | Web UI `→8025` |
|-------|--------------|---------------|
| **Dev** | `localhost:1025` | http://localhost:8025 |
| **Test** | `localhost:1026` | http://localhost:8026 |
| **Prod** | `localhost:1027` | http://localhost:8027 |

> Web UI aynı zamanda REST API end-point: `GET /api/v1/messages`

### 4️⃣ Durdurma

```powershell
.\manage.ps1 stop dev mailhog
```

##  Yapılandırma

### .env Değişkenleri

| Değişken | Açıklama | Varsayılan (Dev) |
|----------|----------|-----------------|
| `MAILHOG_SMTP_PORT` | SMTP port (uygulamadan e-posta gönderim) | `1025` |
| `MAILHOG_WEB_PORT` | Web UI portu | `8025` |

## 💻 .NET Core Kullanım Örnekleri

### NuGet Paketleri

```powershell
# MailKit (önerilen - tam SMTP desteği)
dotnet add package MailKit

# FluentEmail (FluentAPI ile e-posta)
dotnet add package FluentEmail.Core
dotnet add package FluentEmail.Smtp

# Microsoft.AspNetCore için built-in System.Net.Mail de çalışır
```

### appsettings.json Yapılandırması

```json
// appsettings.Development.json
{
  "Email": {
    "SmtpHost": "localhost",
    "SmtpPort": 1025,
    "FromAddress": "noreply@myapp.dev",
    "FromName": "MyApp Development",
    "UseSSL": false,
    "Username": "",
    "Password": ""
  }
}
```

```json
// appsettings.json (Prod - gerçek SMTP)
{
  "Email": {
    "SmtpHost": "smtp.sendgrid.net",
    "SmtpPort": 587,
    "FromAddress": "noreply@myapp.com",
    "FromName": "MyApp",
    "UseSSL": false,
    "Username": "apikey",
    "Password": "SG.your-sendgrid-api-key"
  }
}
```

### MailKit ile E-posta Servisi

```csharp
// Models/EmailMessage.cs
public record EmailMessage(
    string To,
    string Subject,
    string Body,
    bool IsHtml = true,
    IEnumerable<string>? CcAddresses = null
);

// Services/IEmailService.cs
public interface IEmailService
{
    Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default);
    Task SendWelcomeEmailAsync(string toEmail, string userName);
    Task SendPasswordResetAsync(string toEmail, string resetToken);
}

// Services/EmailService.cs
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IOptions<EmailSettings> settings, ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        var email = new MimeMessage();
        email.From.Add(new MailboxAddress(_settings.FromName, _settings.FromAddress));
        email.To.Add(MailboxAddress.Parse(message.To));
        email.Subject = message.Subject;

        if (message.CcAddresses is not null)
            foreach (var cc in message.CcAddresses)
                email.Cc.Add(MailboxAddress.Parse(cc));

        var builder = new BodyBuilder();
        if (message.IsHtml)
            builder.HtmlBody = message.Body;
        else
            builder.TextBody = message.Body;

        email.Body = builder.ToMessageBody();

        using var client = new SmtpClient();
        await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort,
            _settings.UseSSL ? SecureSocketOptions.StartTls : SecureSocketOptions.None,
            cancellationToken);

        if (!string.IsNullOrEmpty(_settings.Username))
            await client.AuthenticateAsync(_settings.Username, _settings.Password, cancellationToken);

        await client.SendAsync(email, cancellationToken);
        await client.DisconnectAsync(true, cancellationToken);

        _logger.LogInformation("Email sent to {Recipient}: {Subject}", message.To, message.Subject);
    }

    public Task SendWelcomeEmailAsync(string toEmail, string userName)
        => SendAsync(new EmailMessage(
            To: toEmail,
            Subject: $"Hoş Geldiniz, {userName}!",
            Body: $"""
                <h1>Merhaba {userName},</h1>
                <p>Hesabınız başarıyla oluşturuldu.</p>
                <p><a href='http://localhost:5000/confirm'>E-postanızı doğrulayın</a></p>
                """));

    public Task SendPasswordResetAsync(string toEmail, string resetToken)
        => SendAsync(new EmailMessage(
            To: toEmail,
            Subject: "Şifre Sıfırlama",
            Body: $"""
                <h1>Şifre Sıfırlama</h1>
                <p>Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:</p>
                <p><a href='http://localhost:5000/reset-password?token={resetToken}'>Şifreyi Sıfırla</a></p>
                <p>Bu bağlantı 1 saat geçerlidir.</p>
                """));
}
```

### DI Kaydı

```csharp
// Models/EmailSettings.cs
public class EmailSettings
{
    public string SmtpHost    { get; set; } = "localhost";
    public int    SmtpPort    { get; set; } = 1025;
    public string FromAddress { get; set; } = "noreply@example.com";
    public string FromName    { get; set; } = "MyApp";
    public bool   UseSSL      { get; set; } = false;
    public string Username    { get; set; } = string.Empty;
    public string Password    { get; set; } = string.Empty;
}

// Program.cs
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));
builder.Services.AddScoped<IEmailService, EmailService>();
```

### Controller'da Kullanım

```csharp
[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IEmailService _emailService;

    public AccountController(IEmailService emailService)
        => _emailService = emailService;

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        // ... kayıt işlemi

        // Hoş geldin e-postası gönder (MailHog'da yakalanır)
        await _emailService.SendWelcomeEmailAsync(request.Email, request.Name);

        return Ok(new { message = "Kayıt başarılı! E-postanızı kontrol edin." });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var token = Guid.NewGuid().ToString("N");
        // ... token kaydet

        await _emailService.SendPasswordResetAsync(request.Email, token);

        return Ok(new { message = "Şifre sıfırlama linki gönderildi." });
    }
}
```

### System.Net.Mail ile Kullanım (Alternatif)

```csharp
// FluentEmail yerine built-in sınıflarla
using System.Net.Mail;

var client = new SmtpClient("localhost", 1025)
{
    EnableSsl  = false,
    Credentials = CredentialCache.DefaultNetworkCredentials
};

var mail = new MailMessage
{
    From       = new MailAddress("noreply@myapp.dev", "MyApp Dev"),
    Subject    = "Test E-postası",
    Body       = "<h1>Test</h1><p>Bu bir test e-postasıdır.</p>",
    IsBodyHtml = true
};
mail.To.Add("user@example.com");

await client.SendMailAsync(mail);
```

### MailHog REST API ile E-posta Doğrulama (Integration Tests)

```csharp
// Tests/EmailVerificationHelper.cs
public class MailHogClient
{
    private readonly HttpClient _httpClient;
    private readonly string _baseUrl;

    public MailHogClient(string baseUrl = "http://localhost:8025")
    {
        _httpClient = new HttpClient();
        _baseUrl = baseUrl;
    }

    // Tüm e-postaları getir
    public async Task<List<MailHogMessage>> GetAllMessagesAsync()
    {
        var response = await _httpClient.GetFromJsonAsync<MailHogResponse>(
            $"{_baseUrl}/api/v1/messages");
        return response?.Items ?? new List<MailHogMessage>();
    }

    // Belirli alıcıya gelen son e-postayı getir
    public async Task<MailHogMessage?> GetLatestMessageForAsync(string email)
    {
        var messages = await GetAllMessagesAsync();
        return messages.FirstOrDefault(m =>
            m.Content.Headers.To.Any(t => t.Contains(email)));
    }

    // Tüm e-postaları temizle
    public async Task DeleteAllMessagesAsync()
        => await _httpClient.DeleteAsync($"{_baseUrl}/api/v1/messages");
}

// Integration test örneği
public class EmailTests : IAsyncLifetime
{
    private readonly MailHogClient _mailhog = new();

    public async Task InitializeAsync() => await _mailhog.DeleteAllMessagesAsync();
    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task Register_ShouldSendWelcomeEmail()
    {
        // Act: kayıt ol
        await _client.PostAsJsonAsync("/api/account/register", new
        {
            email = "test@example.com",
            name  = "Test Kullanıcı"
        });

        // Assert: MailHog'da e-postayı kontrol et
        await Task.Delay(500); // Async gönderim için bekle
        var message = await _mailhog.GetLatestMessageForAsync("test@example.com");

        Assert.NotNull(message);
        Assert.Contains("Hoş Geldiniz", message.Content.Headers.Subject.First());
    }
}
```

## 📬 MailHog Web UI Kullanımı

1. Tarayıcıda http://localhost:8025 açın
2. Gelen e-postalar otomatik listelenir
3. E-postaya tıklayarak içeriği görün (HTML / Plain Text)
4. **Delete All** ile tüm e-postaları temizleyin
5. Sağ üst köşeden yeni e-postalar için **Auto-refresh** aktifleştirin

## 🔍 Sorun Giderme

### E-posta Gönderilmiyor

```powershell
# MailHog container çalışıyor mu?
docker ps | findstr mailhog_dev

# SMTP port açık mı?
Test-NetConnection -ComputerName localhost -Port 1025

# Uygulama ayarlarını kontrol et:
# SmtpHost = "localhost"
# SmtpPort = 1025
# UseSSL   = false
```

### Web UI'e Erişilemiyor

```powershell
# Port çakışması var mı?
netstat -ano | findstr :8025

# Container loglarını kontrol et
.\manage.ps1 logs dev mailhog
```

### E-postalar Görünmüyor

```csharp
// async gönderimde await kullandığınızdan emin olun
await _emailService.SendAsync(message);  // ✅
_emailService.SendAsync(message);         // ❌ fire-and-forget
```

## 🔒 Güvenlik Notları

> ⚠️ **MailHog production'da kullanılmamalıdır!**
>
> - Gerçek e-posta göndermez
> - Şifre koruması yoktur
> - Tüm e-postalar web UI'da görünür
>
> Production'da **SendGrid**, **Mailgun**, **Amazon SES**, **SMTP2GO** gibi gerçek bir SMTP servisi kullanın.

## ✅ Kontrol Listesi

- [ ] `SmtpHost=localhost` ve `SmtpPort=1025` ayarlandı mı?
- [ ] `UseSSL=false` olarak ayarlandı mı?
- [ ] E-posta gönderimi http://localhost:8025'te görünüyor mu?
- [ ] Production ortamı gerçek SMTP servisine yönlendiriliyor mu?

## 🎯 Sonraki Adımlar

1. **E-posta Şablonları**: Razor/Fluid template engine entegrasyonu
2. **Queue ile Gönderim**: RabbitMQ üzerinden async e-posta kuyruğu
3. **Production SMTP**: SendGrid/Mailgun yapılandırması
4. **Integration Tests**: MailHog API ile otomatik e-posta doğrulama
5. **Rate Limiting**: Aynı alıcıya çoklu e-posta koruması

---

**Hazırlayan**: Docker MailHog Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Ana dokümantasyon: [README.md](README.md)  
📧 MailHog Detayları: [README-MailHog.md](README-MailHog.md)  
📘 PostgreSQL Detayları: [README-PostgreSQL.md](README-PostgreSQL.md)  
🔴 MSSQL Detayları: [README-MSSQL.md](README-MSSQL.md)  
📕 Redis Detayları: [README-Redis.md](README-Redis.md)  
📙 RabbitMQ Detayları: [README-RabbitMQ.md](README-RabbitMQ.md)  
📗 Elasticsearch Detayları: [README-Elasticsearch.md](README-Elasticsearch.md)  
🍃 MongoDB Detayları: [README-MongoDB.md](README-MongoDB.md)  
📊 Monitoring Detayları: [README-Monitoring.md](README-Monitoring.md)  
🔐 Keycloak Detayları: [README-Keycloak.md](README-Keycloak.md)  
📋 Seq Detayları: [README-Seq.md](README-Seq.md)

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
