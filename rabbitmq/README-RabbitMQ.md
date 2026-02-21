# RabbitMQ Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment RabbitMQ + Management UI kurulumu.

## 📁 Klasör Yapısı

```
rabbitmq/
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

- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Temiz Yapı**: Her ortam için ayrı docker-compose.yml
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Best Practices**: Docker ve DevOps standartlarına uygun
- ✅ **Management UI**: Web tabanlı yönetim arayüzü
- ✅ **Persistence**: Volume'ler ile veri kalıcılığı

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item rabbitmq\environments\dev\.env.example rabbitmq\environments\dev\.env
Copy-Item rabbitmq\environments\test\.env.example rabbitmq\environments\test\.env
Copy-Item rabbitmq\environments\prod\.env.example rabbitmq\environments\prod\.env
```

**Her ortam için portları ayarlayın:**

- **Dev:** `RABBITMQ_PORT=5672`, `RABBITMQ_MANAGEMENT_PORT=15672`
- **Test:** `RABBITMQ_PORT=5673`, `RABBITMQ_MANAGEMENT_PORT=15673`
- **Prod:** `RABBITMQ_PORT=5674`, `RABBITMQ_MANAGEMENT_PORT=15674`

**Güvenlik için şifreleri değiştirin:**

```powershell
# environments/dev/.env içeriği
RABBITMQ_PASSWORD=güçlü_dev_şifresi

# environments/test/.env içeriği
RABBITMQ_PASSWORD=güçlü_test_şifresi

# environments/prod/.env içeriği
RABBITMQ_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
```

### 2️⃣ Ortamı Başlatma

**Yönetim Scripti (Önerilen):**

```powershell
# Windows PowerShell
.\manage.ps1 start dev rabbitmq
```

### 3️⃣ Erişim

| Ortam | AMQP `→5672` | Management UI `→15672` |
|-------|--------------|------------------------|
| **Dev** | `localhost:5672` | http://localhost:15672 |
| **Test** | `localhost:5673` | http://localhost:15673 |
| **Prod** | `localhost:5674` | http://localhost:15674 |

## 📖 Kullanım Kılavuzu

### Yönetim Scriptleri

```powershell
# BAŞLATMA
.\manage.ps1 start dev rabbitmq      # Development başlat
.\manage.ps1 start test rabbitmq     # Test başlat
.\manage.ps1 start prod rabbitmq     # Production başlat

# DURDURMA
.\manage.ps1 stop dev rabbitmq       # Development durdur
.\manage.ps1 stop test rabbitmq      # Test durdur

# YENİDEN BAŞLATMA
.\manage.ps1 restart dev rabbitmq    # Development yeniden başlat

# LOGLARI İZLEME
.\manage.ps1 logs dev rabbitmq       # Development logları (Ctrl+C ile çık)

# DURUM KONTROLÜ
.\manage.ps1 status dev rabbitmq     # Development durumu
.\manage.ps1 status prod rabbitmq    # Production durumu

# TEMİZLEME (VERİLER SİLİNİR!)
.\manage.ps1 clean dev rabbitmq      # Development ortamını temizle
```

**Not:** Windows'ta ilk kullanımda şu komutu çalıştırmanız gerekebilir:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Manuel Docker Compose Kullanımı

Her ortam kendi klasöründe bağımsız çalışır:

```powershell
# Development ortamında
Set-Location environments\dev
docker-compose up -d        # Başlat
docker-compose down         # Durdur
docker-compose logs -f      # Logları izle
docker-compose ps           # Durum
docker-compose restart      # Yeniden başlat
docker-compose down -v      # Verilerle birlikte sil

# Test ortamında
Set-Location environments\test
docker-compose up -d

# Production ortamında
Set-Location environments\prod
docker-compose up -d
```

**Kök dizinden çalıştırma:**

```powershell
# Development
docker-compose -f environments/dev/docker-compose.yml up -d
docker-compose -f environments/dev/docker-compose.yml down

# Test
docker-compose -f environments/test/docker-compose.yml up -d
docker-compose -f environments/test/docker-compose.yml down

# Production
docker-compose -f environments/prod/docker-compose.yml up -d
docker-compose -f environments/prod/docker-compose.yml down
```

## 🔧 Yapılandırma

Her ortamın kendi `.env` dosyası vardır:

**environments/dev/.env:**
```env
# RabbitMQ Settings
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=güçlü_şifre_buraya
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672
```

### Port Yapılandırması

Default portlar:
- **Dev**: AMQP 5672, Management 15672
- **Test**: AMQP 5673, Management 15673
- **Prod**: AMQP 5674, Management 15674

Port değiştirmek için ilgili ortamın `.env` dosyasını düzenleyin.

## 🔌 RabbitMQ'ya Bağlanma

### Management UI'dan Erişim

1. Management UI'a giriş yapın (http://localhost:15672 - dev için)
2. Kullanıcı adı ve şifre ile giriş yapın:
   - **Username**: `.env` dosyasındaki `RABBITMQ_USER`
   - **Password**: `.env` dosyasındaki `RABBITMQ_PASSWORD`

### Management UI Özellikleri

- **Overview**: Genel sistem durumu, mesaj istatistikleri
- **Connections**: Aktif bağlantılar
- **Channels**: Açık channel'lar
- **Exchanges**: Exchange listesi ve yönetimi
- **Queues**: Queue listesi ve mesaj inceleme
- **Admin**: Kullanıcı ve vhost yönetimi

### Uygulama veya Harici Araçlardan Bağlanma

**Development:**
```
Host: localhost
Port: 5672
Virtual Host: /
Username: (environments/dev/.env içinde)
Password: (environments/dev/.env içinde)
```

**Test:**
```
Host: localhost
Port: 5673
Virtual Host: /
Username: (environments/test/.env içinde)
Password: (environments/test/.env içinde)
```

**Production:**
```
Host: localhost
Port: 5674
Virtual Host: /
Username: (environments/prod/.env içinde)
Password: (environments/prod/.env içinde)
```

**.NET örneği (RabbitMQ.Client):**
```csharp
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;

// Bağlantı oluştur
var factory = new ConnectionFactory
{
    HostName = "localhost",
    Port = 5672,
    UserName = "admin",
    Password = "your_password",
    VirtualHost = "/"
};

using var connection = factory.CreateConnection();
using var channel = connection.CreateModel();

// Queue oluştur (durable=true, kalıcı)
channel.QueueDeclare(
    queue: "hello",
    durable: true,
    exclusive: false,
    autoDelete: false,
    arguments: null
);

// Mesaj gönder
string message = "Hello RabbitMQ from .NET!";
var body = Encoding.UTF8.GetBytes(message);

var properties = channel.CreateBasicProperties();
properties.Persistent = true; // Mesajı kalıcı yap

channel.BasicPublish(
    exchange: "",
    routingKey: "hello",
    basicProperties: properties,
    body: body
);

Console.WriteLine($" [x] Sent '{message}'");

// Consumer (Mesaj alma)
var consumer = new EventingBasicConsumer(channel);
consumer.Received += (model, ea) =>
{
    var receivedBody = ea.Body.ToArray();
    var receivedMessage = Encoding.UTF8.GetString(receivedBody);
    Console.WriteLine($" [x] Received '{receivedMessage}'");
    
    // Manuel ACK
    channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
};

channel.BasicConsume(
    queue: "hello",
    autoAck: false,  // Manuel acknowledge
    consumer: consumer
);
```

**NuGet Paketi:**
```powershell
dotnet add package RabbitMQ.Client
```

**ASP.NET Core ile Producer/Consumer:**
```csharp
// Producer Service
public class RabbitMQProducer
{
    private readonly IConnection _connection;
    private readonly IModel _channel;

    public RabbitMQProducer()
    {
        var factory = new ConnectionFactory
        {
            HostName = "localhost",
            Port = 5672,
            UserName = "admin",
            Password = "your_password"
        };

        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();

        _channel.QueueDeclare(
            queue: "orders",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );
    }

    public void SendMessage(string message)
    {
        var body = Encoding.UTF8.GetBytes(message);
        var properties = _channel.CreateBasicProperties();
        properties.Persistent = true;

        _channel.BasicPublish(
            exchange: "",
            routingKey: "orders",
            basicProperties: properties,
            body: body
        );

        Console.WriteLine($"Sent: {message}");
    }

    public void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
    }
}

// Consumer Background Service
public class RabbitMQConsumer : BackgroundService
{
    private readonly IConnection _connection;
    private readonly IModel _channel;

    public RabbitMQConsumer()
    {
        var factory = new ConnectionFactory
        {
            HostName = "localhost",
            Port = 5672,
            UserName = "admin",
            Password = "your_password"
        };

        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();

        _channel.QueueDeclare(
            queue: "orders",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var consumer = new EventingBasicConsumer(_channel);
        
        consumer.Received += (model, ea) =>
        {
            var body = ea.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);
            
            Console.WriteLine($"Received: {message}");
            
            // İşlemi yap...
            
            // ACK gönder
            _channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
        };

        _channel.BasicConsume(
            queue: "orders",
            autoAck: false,
            consumer: consumer
        );

        return Task.CompletedTask;
    }

    public override void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
        base.Dispose();
    }
}

// Program.cs'de kayıt
builder.Services.AddSingleton<RabbitMQProducer>();
builder.Services.AddHostedService<RabbitMQConsumer>();
```

##  Veri Kalıcılığı (Persistence)

Her ortam için ayrı named volumes kullanılır:

**Development:**
- `rabbitmq_dev_data` - RabbitMQ verileri (queues, exchanges, messages)
- `rabbitmq_dev_logs` - RabbitMQ logları

**Test:**
- `rabbitmq_test_data`
- `rabbitmq_test_logs`

**Production:**
- `rabbitmq_prod_data`
- `rabbitmq_prod_logs`

### Volume Yönetimi

```powershell
# Tüm RabbitMQ volumes listele
docker volume ls | Select-String rabbitmq

# Belirli bir volume'u incele
docker volume inspect rabbitmq_dev_data

# Volume'u manuel sil (container durdurulmuş olmalı)
docker volume rm rabbitmq_dev_data
```

## 🛡️ Güvenlik En İyi Pratikleri

### 1. Şifre Güvenliği
```powershell
# ❌ YANLIŞ - Zayıf şifre
RABBITMQ_PASSWORD=guest

# ✅ DOĞRU - Güçlü şifre
RABBITMQ_PASSWORD=Kx9&mP2$vL8@qR5#wN3!
```

### 2. Environment Ayrımı
- Development ve Test için basit şifreler kullanabilirsiniz
- Production için **mutlaka** güçlü, benzersiz şifreler kullanın
- Production şifrelerini asla development ile aynı yapmayın
- Default "guest" kullanıcısını production'da kullanmayın

### 3. Git Güvenliği
`.gitignore` dosyası `.env` dosyalarını otomatik olarak hariç tutar:
```gitignore
environments/*/.env
```

**Kontrol edin:**
```powershell
git status  # .env dosyaları listede olmamalı
```

### 4. Şifre Yönetimi
- Şifreleri bir şifre yöneticisinde saklayın (1Password, LastPass, vb.)
- Ekip üyeleriyle güvenli kanallardan paylaşın (Slack değil!)
- Production şifrelerini sık sık değiştirin

### 5. RabbitMQ Güvenlik Ayarları
- Always use strong credentials
- Disable guest user in production
- Use SSL/TLS for production connections
- Limit network access with firewall rules
- Create specific users for each application

## 📊 İzleme ve Bakım

### Container Durumunu Kontrol Etme

**Script ile:**
```powershell
.\manage.ps1 status dev rabbitmq
```

**Manuel:**
```powershell
# Tüm containerlar
docker ps

# RabbitMQ containerları
docker ps | Select-String rabbitmq

# Belirli bir ortam
Set-Location environments\dev
docker-compose ps
```

### Disk Kullanımı
```powershell
# Volume'leri listele
docker volume ls | Select-String rabbitmq

# Volume boyutunu kontrol et
docker system df -v
```

### Logları İnceleme

**Script ile:**
```powershell
# Canlı log izleme
.\manage.ps1 logs dev rabbitmq
```

**Manuel:**
```powershell
# Development ortamı
Set-Location environments\dev
docker-compose logs -f

# Son 100 satır
docker-compose logs --tail=100

# Container logları
docker logs rabbitmq_dev
```

### Backup Alma

```powershell
# RabbitMQ definitions export - Windows PowerShell
docker exec rabbitmq_dev rabbitmqctl export_definitions /tmp/definitions.json
docker cp rabbitmq_dev:/tmp/definitions.json "backup_dev_$(Get-Date -Format 'yyyyMMdd').json"

# Import etme
docker cp backup_dev_20260221.json rabbitmq_dev:/tmp/definitions.json
docker exec rabbitmq_dev rabbitmqctl import_definitions /tmp/definitions.json
```

## 🐛 Sorun Giderme

### Port Zaten Kullanılıyor

**Problemi tespit edin:**
```powershell
# Windows - Port kontrolü
netstat -ano | findstr :5672
```

**Çözüm:** İlgili ortamın `.env` dosyasında portu değiştirin:
```env
RABBITMQ_PORT=5675
RABBITMQ_MANAGEMENT_PORT=15675
```

### Container Başlamıyor

```powershell
# Logları kontrol et
Set-Location environments\dev
docker-compose logs

# Container'ı yeniden oluştur
docker-compose down
docker-compose up -d --force-recreate

# Volume sorunları varsa
docker-compose down -v
docker-compose up -d
```

### Management UI'a Erişilemiyor

```powershell
# RabbitMQ hazır mı kontrol et
docker exec rabbitmq_dev rabbitmq-diagnostics ping

# Network bağlantısını kontrol et
docker network inspect rabbitmq_dev_network

# Container'ı yeniden başlat
Set-Location environments\dev
docker-compose restart
```

### Mesajlar Kayboldu

```powershell
# 1. Backup aldıysanız restore edin
# 2. Logları kontrol edin
docker logs rabbitmq_dev

# 3. Queue durumunu kontrol edin
docker exec rabbitmq_dev rabbitmqctl list_queues

# 4. Yoksa temizleyip yeniden başlatın
.\manage.ps1 clean dev rabbitmq
.\manage.ps1 start dev rabbitmq
```

### Script Çalışmıyor (Windows)

```powershell
# PowerShell execution policy sorunuysa
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Sonra tekrar deneyin
.\manage.ps1 start dev rabbitmq
```

## 🔄 Güncelleme ve Bakım

### RabbitMQ Versiyonunu Güncelleme

1. İlgili ortamın `docker-compose.yml` dosyasını düzenleyin:
```yaml
image: rabbitmq:3.13-management-alpine  # 3-management-alpine yerine
```

2. Ortamı yeniden oluşturun:
```powershell
Set-Location environments\dev
docker-compose down
docker-compose pull
docker-compose up -d
```

### Ortamı Temizleme

```powershell
# UYARI: Ortamdaki tüm veriler silinir!

# Script ile
.\manage.ps1 clean dev rabbitmq

# veya Manuel
Set-Location environments\dev
docker-compose down -v
Set-Location ../..
```

## 💡 İpuçları ve Best Practices

1. **Geliştirme sırasında** sadece dev ortamını çalıştırın
2. **Test etmeden önce** test ortamını başlatın
3. **Production'ı** sadece deploy için kullanın
4. **Düzenli backup** alın, özellikle production için
5. **Logları** düzenli kontrol edin
6. **Disk alanını** izleyin, gereksiz volume'leri temizleyin
7. **Her ortamın .env dosyasını** farklı şifrelerle yapılandırın
8. **Queue'leri** durable yaparak mesaj kaybını önleyin
9. **Memory ve disk limit** ayarlayın production için
10. **Dead Letter Exchange** kullanarak hata yönetimi yapın

## 🎯 Ortamlar Arası Geçiş

```powershell
# Development'tan Test'e geçiş
.\manage.ps1 stop dev rabbitmq
.\manage.ps1 start test rabbitmq

# Sadece Production
.\manage.ps1 stop dev rabbitmq
.\manage.ps1 stop test rabbitmq
.\manage.ps1 start prod rabbitmq
```

## 🔍 Örnek Senaryolar

### Senaryo 1: Yeni Proje Başlangıcı

```powershell
# 1. Şifreleri güncelle
code environments/dev/.env

# 2. Development ortamını başlat
.\manage.ps1 start dev rabbitmq

# 3. Management UI'a giriş yap
# http://localhost:15672

# 4. Çalışmayı bitirince durdur
.\manage.ps1 stop dev rabbitmq
```

### Senaryo 2: Test Ortamında Çalışma

```powershell
# 1. Test ortamını başlat
Set-Location environments\test
docker-compose up -d

# 2. Logları izle
docker-compose logs -f

# 3. Bitirince durdur
docker-compose down
```

### Senaryo 3: Production Deploy

```powershell
# 1. Production .env'i güvenli şifrelerle güncelle
code environments/prod/.env

# 2. Production'ı başlat
.\manage.ps1 start prod rabbitmq

# 3. Health check
docker ps | Select-String prod

# 4. Logları kontrol et
.\manage.ps1 logs prod rabbitmq

# 5. Management UI'dan kontrol
# http://localhost:15674
```

### Senaryo 4: Message Queue Kullanımı

```powershell
# Development başlat
.\manage.ps1 start dev rabbitmq

# .NET ile mesaj gönder
# using RabbitMQ.Client;
var factory = new ConnectionFactory
{
    HostName = "localhost",
    Port = 5672,
    UserName = "admin",
    Password = "password"
};
using var connection = factory.CreateConnection();
using var channel = connection.CreateModel();
channel.QueueDeclare(queue: "task_queue", durable: true, exclusive: false, autoDelete: false, arguments: null);
var body = Encoding.UTF8.GetBytes("Hello from .NET");
channel.BasicPublish(exchange: "", routingKey: "task_queue", basicProperties: null, body: body);
```

## 📚 Ek Kaynaklar

- [RabbitMQ Resmi Dokümantasyon](https://www.rabbitmq.com/documentation.html)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [RabbitMQ Management Plugin](https://www.rabbitmq.com/management.html)
- [Docker Compose Referans](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [RabbitMQ Best Practices](https://www.rabbitmq.com/production-checklist.html)

## ❓ Sık Sorulan Sorular

**S: Neden her ortam için ayrı klasör?**
A: İzolasyon, bağımsızlık ve karışıklığı önlemek için. Her ortam kendi bağımsız ekosisteminde çalışır.

**S: Tüm ortamları aynı anda çalıştırabilir miyim?**
A: Evet, her ortam farklı portlarda olduğu için sorunsuzca çalışabilir.

**S: Guest kullanıcısı neden çalışmıyor?**
A: Güvenlik nedeniyle guest kullanıcısı sadece localhost'tan bağlanabilir. Uzak bağlantılar için özel kullanıcı oluşturun.

**S: Production'da restart policy neden "always"?**
A: Container manuel olarak durdurulana kadar sürekli çalışmasını sağlar. Sunucu yeniden başladığında otomatik başlar.

**S: Mesajlar container restart'ta silinir mi?**
A: Hayır, durable queue'ler ve persistent message'lar volume'de saklandığı için korunur.

**S: Management UI şifresini unuttum, ne yapmalıyım?**
A: `.env` dosyasındaki şifreyi değiştirin ve container'ı yeniden başlatın.

## ✅ Kontrol Listesi

Kurulum sonrası kontrol:

- [ ] Tüm container'lar çalışıyor mu? (`docker-compose ps`)
- [ ] RabbitMQ'ya bağlanabiliyor musunuz?
- [ ] Management UI açılıyor mu? (http://localhost:15672)
- [ ] Şifreler değiştirildi mi? (Production için)
- [ ] Firewall kuralları ayarlandı mı? (Production için)
- [ ] Backup stratejisi belirlendi mi?
- [ ] Message persistence aktif mi?
- [ ] Memory limit ayarlandı mı? (Production için)

## 🎯 Sonraki Adımlar

1. **Monitoring**: Management UI'dan metrik takibi yapın
2. **Alerting**: Kritik durumlar için alert kurulumu yapın
3. **Backup**: Otomatik definitions backup scriptleri oluşturun
4. **Documentation**: Özel kullanım senaryolarınızı belgeleyin
5. **Security**: Production şifrelerini ve network kurallarını gözden geçirin
6. **Performance**: Queue ve consumer optimizasyonu yapın
7. **High Availability**: Gerekirse RabbitMQ cluster kurun

---

**Hazırlayan**: Docker RabbitMQ Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
