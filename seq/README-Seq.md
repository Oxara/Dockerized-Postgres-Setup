# Seq Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **Seq** (Structured Log Server) kurulumu. .NET uygulamalarından **Serilog** veya **NLog** ile doğrudan log gönderimi desteklenir.

## 📁 Klasör Yapısı

```
seq/
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

## ✨ Özellikler

- ✅ **Seq Latest**: Tam özellikli structured log server
- ✅ **Web UI**: Gerçek zamanlı log görüntüleme ve arama
- ✅ **Serilog / NLog Desteği**: Doğrudan sink entegrasyonu
- ✅ **SQL benzeri Sorgular**: FilterExpressions ile gelişmiş log arama
- ✅ **Alert Destegi**: Log tabanlı alert kuralları
- ✅ **Veri Kalıcılığı**: Volume ile loglar restart sonrası korunur
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

```powershell
Copy-Item seq\environments\dev\.env.example seq\environments\dev\.env
```

### 2️⃣ Başlatma

```powershell
.\manage.ps1 start dev seq
```

### 3️⃣ Erişim

| Ortam | Seq Web UI + Ingestion `→80` |
|-------|------------------------------|
| **Dev** | http://localhost:5341 |
| **Test** | http://localhost:5342 |
| **Prod** | http://localhost:5343 |

> Web UI ve log ingestion aynı port üzerinden çalışır. Dev ortamında şifre yoktur.

### 4️⃣ Durdurma

```powershell
.\manage.ps1 stop dev seq
```

##  Yapılandırma

### .env Değişkenleri

| Değişken | Açıklama | Varsayılan (Dev) |
|----------|----------|-----------------|
| `SEQ_PORT` | Seq web UI + ingestion portu | `5341` |
| `SEQ_ADMIN_PASSWORD_HASH` | (Prod) Admin şifre hash | _(boş)_ |

## 💻 .NET Core Kullanım Örnekleri

### NuGet Paketleri

```powershell
# Serilog (önerilen)
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Seq

# NLog için
dotnet add package NLog.Web.AspNetCore
dotnet add package NLog.Targets.Seq
```

### Serilog ile Seq Entegrasyonu

```csharp
// Program.cs
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithEnvironmentName()
    .WriteTo.Console()
    .WriteTo.Seq("http://localhost:5341")   // Dev ortamı
    .CreateLogger();

builder.Host.UseSerilog();
```

```csharp
// appsettings.json ile yapılandırma
```

```json
// appsettings.json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.Seq"],
    "MinimumLevel": {
      "Default": "Debug",
      "Override": {
        "Microsoft": "Information",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" },
      {
        "Name": "Seq",
        "Args": {
          "serverUrl": "http://localhost:5341",
          "restrictedToMinimumLevel": "Debug"
        }
      }
    ],
    "Enrich": ["FromLogContext", "WithMachineName", "WithThreadId"]
  }
}
```

```csharp
// Program.cs - appsettings.json ile yapılandırma
builder.Host.UseSerilog((context, services, configuration) =>
    configuration.ReadFrom.Configuration(context.Configuration)
                 .ReadFrom.Services(services)
                 .Enrich.FromLogContext());
```

### Structured Logging Kullanımı

```csharp
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(ILogger<OrdersController> logger)
        => _logger = logger;

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        // Structured log — Seq'te filtrelenebilir property'ler
        _logger.LogInformation(
            "Order creation requested: {CustomerId} - {ProductId} x{Quantity}",
            request.CustomerId, request.ProductId, request.Quantity);

        try
        {
            var orderId = Guid.NewGuid();
            // ... iş mantığı

            _logger.LogInformation(
                "Order created successfully: {OrderId} for {CustomerId}",
                orderId, request.CustomerId);

            return Ok(new { orderId });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to create order for {CustomerId}",
                request.CustomerId);
            return StatusCode(500);
        }
    }
}
```

### LogContext ile Zenginleştirme

```csharp
using Serilog.Context;

// HTTP request ID'yi her log'a ekle
app.Use(async (ctx, next) =>
{
    var requestId = Guid.NewGuid().ToString("N")[..8];
    using (LogContext.PushProperty("RequestId", requestId))
    using (LogContext.PushProperty("UserId", ctx.User.FindFirst("sub")?.Value ?? "anonymous"))
    {
        await next();
    }
});
```

### Seq Sink API Key ile Güvenli Gönderim (Production)

```csharp
// Production — API key ile
.WriteTo.Seq(
    serverUrl: "http://localhost:5343",
    apiKey: builder.Configuration["Seq:ApiKey"])  // Seq UI'dan oluşturulan API key
```

```json
// appsettings.Production.json
{
  "Serilog": {
    "WriteTo": [
      {
        "Name": "Seq",
        "Args": {
          "serverUrl": "http://localhost:5343",
          "apiKey": "your-seq-api-key-here",
          "restrictedToMinimumLevel": "Warning"
        }
      }
    ]
  },
  "Seq": {
    "ApiKey": "your-seq-api-key-here"
  }
}
```

### NLog ile Seq Entegrasyonu

```xml
<!-- nlog.config -->
<?xml version="1.0" encoding="utf-8"?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd">
  <extensions>
    <add assembly="NLog.Targets.Seq"/>
  </extensions>
  <targets>
    <target name="seq" xsi:type="Seq" serverUrl="http://localhost:5341">
      <property name="Application" value="MyApp" />
      <property name="Environment" value="Development" />
    </target>
  </targets>
  <rules>
    <logger name="*" minlevel="Debug" writeTo="seq" />
  </rules>
</nlog>
```

### Serilog ile Performans İzleme

```csharp
// Başlangıç saatini kaydet
using var timer = _logger.BeginTimedOperation("ProcessOrder");

// İşlem yap
await ProcessOrderAsync(orderId);

// Otomatik süre logu atar (Serilog.Timings paketi)
// Veya manuel:
var elapsed = timer.Elapsed;
_logger.LogInformation("ProcessOrder completed in {ElapsedMs}ms for {OrderId}",
    elapsed.TotalMilliseconds, orderId);
```

### Seq'te Log Arama (FilterExpressions)

Seq web UI'da sorgular SQL benzeri söz dizimiyle yazılır:

```sql
-- Belirli controller'dan gelen hatalar
@Level = 'Error' and SourceContext like 'Orders%'

-- Belirli kullanıcının son 1 saatteki işlemleri
UserId = '12345' and @Timestamp > Now() - 1h

-- Yavaş işlemler (200ms üzeri)
ElapsedMs > 200

-- Exception tipi filtresi
@Exception like '*SqlException*'

-- Birden fazla koşul
@Level in ['Warning', 'Error'] and Application = 'MyAPI'
```

## 📋 Seq Yönetimi (Web UI)

### Signal Oluşturma

Seq UI → **Signals** → New Signal:
- İsim: `API Errors`
- Filter: `@Level = 'Error' and SourceContext like '*.Controllers.*'`

### Alert Kuralı

Seq UI → **Alerts** → New Alert:
- Signal: `API Errors`
- Koşul: 5 dakikada 10'dan fazla hata
- Bildirim: webhook (Slack, Teams, vb.)

### API Key Oluşturma (Production)

Seq UI → **Settings** → **API Keys** → Add API Key:
- Title: `MyApp Production`
- Minimum Level: `Warning`

## 🔍 Sorun Giderme

### Log Gönderilmiyor

```powershell
# Seq container'ın çalıştığını doğrula
docker ps | findstr seq_dev

# Seq endpoint'i test et
Invoke-WebRequest -Uri "http://localhost:5341/api/events/raw" -Method Get

# Serilog sink konfigürasyonunu kontrol et (serverUrl doğru mu?)
```

### "Connection refused" Hatası

```csharp
// Seq bağlantısı başarısız olsa da uygulama çalışmaya devam etmeli
// Serilog Seq sink varsayılan olarak fire-and-forget
// Hata durumunda Console'a yazar
```

### Disk Doldu

```powershell
# Volume boyutunu kontrol et
docker volume inspect seq_dev_data

# Seq UI → Settings → Storage → Retention Policy
# Log retention süresini kısaltın
```

## 🔒 Güvenlik Notları

### Development/Test
- Şifre yoktur — localhost erişimi yeterli
- Tüm loglar herkes tarafından görülebilir

### Production
- `SEQ_ADMIN_PASSWORD_HASH` ile admin şifresi zorunludur
- Seq UI'yı public internet'e açmayın
- API Key kullanarak log gönderin
- Retention policy ile disk kullanımını kontrol edin

## ✅ Production Kontrol Listesi

- [ ] `SEQ_ADMIN_PASSWORD_HASH` ayarlandı mı?
- [ ] API Key oluşturulup uygulamaya eklendi mi?
- [ ] Retention policy yapılandırıldı mı?
- [ ] Seq UI dışarıya kapatıldı mı (firewall)?
- [ ] Alert kuralları tanımlandı mı?

## 🎯 Sonraki Adımlar

1. **Signal Dashboard**: Servis bazlı log dashboard'ları oluşturun
2. **Alert Entegrasyonu**: Teams/Slack webhook ekleyin
3. **Retention Policy**: Log saklama süresini yapılandırın
4. **Application Property**: Tüm logları `Application` property ile etiketleyin
5. **Correlation ID**: Distributed tracing için `CorrelationId` ekleyin

---

**Hazırlayan**: Docker Seq Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Ana dokümantasyon: [README.md](README.md)  
📋 Seq Detayları: [README-Seq.md](README-Seq.md)  
📘 PostgreSQL Detayları: [README-PostgreSQL.md](README-PostgreSQL.md)  
🔴 MSSQL Detayları: [README-MSSQL.md](README-MSSQL.md)  
📕 Redis Detayları: [README-Redis.md](README-Redis.md)  
📙 RabbitMQ Detayları: [README-RabbitMQ.md](README-RabbitMQ.md)  
📗 Elasticsearch Detayları: [README-Elasticsearch.md](README-Elasticsearch.md)  
🍃 MongoDB Detayları: [README-MongoDB.md](README-MongoDB.md)  
📊 Monitoring Detayları: [README-Monitoring.md](README-Monitoring.md)  
🔐 Keycloak Detayları: [README-Keycloak.md](README-Keycloak.md)  
📧 MailHog Detayları: [README-MailHog.md](README-MailHog.md)

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
