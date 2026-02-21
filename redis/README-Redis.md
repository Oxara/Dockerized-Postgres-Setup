# Redis Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment Redis + RedisInsight kurulumu.

## 📁 Klasör Yapısı

```
redis/
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
- ✅ **Modern UI**: RedisInsight ile Redis veri yönetimi

- ✅ **Persistence**: AOF (Append Only File) ile veri kalıcılığı

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item redis\environments\dev\.env.example redis\environments\dev\.env
Copy-Item redis\environments\test\.env.example redis\environments\test\.env
Copy-Item redis\environments\prod\.env.example redis\environments\prod\.env
```

**Her ortam için portları ayarlayın:**

- **Dev:** `REDIS_PORT=6379`, `REDISINSIGHT_PORT=8001`
- **Test:** `REDIS_PORT=6380`, `REDISINSIGHT_PORT=8002`
- **Prod:** `REDIS_PORT=6381`, `REDISINSIGHT_PORT=8003`

**Güvenlik için şifreleri değiştirin:**

```powershell
# environments/dev/.env içeriği
REDIS_PASSWORD=güçlü_dev_şifresi

# environments/test/.env içeriği
REDIS_PASSWORD=güçlü_test_şifresi

# environments/prod/.env
REDIS_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
```

### 2️⃣ Ortamı Başlatma

**Yönetim Scriptleri (Önerilen):**

```powershell
.\manage.ps1 start dev redis
```

### 3️⃣ Erişim

| Ortam | Redis | RedisInsight |
|-------|-------|-------------|
| **Dev** | `localhost:6379` | http://localhost:8001 |
| **Test** | `localhost:6380` | http://localhost:8002 |
| **Prod** | `localhost:6381` | http://localhost:8003 |

## 📖 Kullanım Kılavuzu

### Yönetim Scripti

```powershell
# BAŞLATMA
.\manage.ps1 start dev redis      # Development başlat
.\manage.ps1 start test redis     # Test başlat
.\manage.ps1 start prod redis     # Production başlat

# DURDURMA
.\manage.ps1 stop dev redis       # Development durdur
.\manage.ps1 stop test redis      # Test durdur

# YENİDEN BAŞLATMA
.\manage.ps1 restart dev redis    # Development yeniden başlat

# LOGLARI İZLEME
.\manage.ps1 logs dev redis       # Development logları (Ctrl+C ile çık)

# DURUM KONTROLÜ
.\manage.ps1 status dev redis     # Development durumu
.\manage.ps1 status prod redis    # Production durumu

# TEMİZLEME (VERİLER SİLİNİR!)
.\manage.ps1 clean dev redis      # Development ortamını temizle
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
# Redis Settings
REDIS_PASSWORD=güçlü_şifre_buraya
REDIS_PORT=6379

# RedisInsight Settings
REDISINSIGHT_PORT=8001
```

### Port Yapılandırması

Default portlar:
- **Dev**: Redis 6379, RedisInsight 8001
- **Test**: Redis 6380, RedisInsight 8002
- **Prod**: Redis 6381, RedisInsight 8003

Port değiştirmek için ilgili ortamın `.env` dosyasını düzenleyin.

## 🔌 Redis'e Bağlanma

### RedisInsight'tan Bağlanma

1. RedisInsight'a giriş yapın (http://localhost:8001 - dev için)
2. "Add Redis Database" butonuna tıklayın
3. Connection bilgilerini girin:
   - **Host**: `redis` (container adı - aynı network'te)
   - **Port**: `6379` (container içi port)
   - **Password**: `.env` dosyasındaki `REDIS_PASSWORD`
4. "Add Redis Database" ile ekleyin

### Uygulama veya Harici Araçlardan Bağlanma

**Development:**
```
Host: localhost
Port: 6379
Password: (environments/dev/.env içinde)
```

**Test:**
```
Host: localhost
Port: 6380
Password: (environments/test/.env içinde)
```

**Production:**
```
Host: localhost
Port: 6381
Password: (environments/prod/.env içinde)
```

**.NET Core örneği (StackExchange.Redis):**
```csharp
using StackExchange.Redis;

// Bağlantı oluştur
var options = ConfigurationOptions.Parse("localhost:6379");
options.Password = "redis_dev_password";

var redis = ConnectionMultiplexer.Connect(options);
var db = redis.GetDatabase();

// String operations
await db.StringSetAsync("mykey", "Hello Redis from .NET");
var value = await db.StringGetAsync("mykey");
Console.WriteLine(value);

// Hash operations
await db.HashSetAsync("user:1000", new HashEntry[] {
    new HashEntry("name", "John Doe"),
    new HashEntry("email", "john@example.com"),
    new HashEntry("age", "30")
});

var userName = await db.HashGetAsync("user:1000", "name");
Console.WriteLine($"User name: {userName}");

// List operations
await db.ListRightPushAsync("mylist", "item1");
await db.ListRightPushAsync("mylist", "item2");
await db.ListRightPushAsync("mylist", "item3");

var listItems = await db.ListRangeAsync("mylist");
foreach (var item in listItems)
{
    Console.WriteLine(item);
}

// Set operations
await db.SetAddAsync("myset", new RedisValue[] { "apple", "banana", "orange" });
var setMembers = await db.SetMembersAsync("myset");

// Pub/Sub
var sub = redis.GetSubscriber();
await sub.SubscribeAsync("mychannel", (channel, message) =>
{
    Console.WriteLine($"Received: {message}");
});

await sub.PublishAsync("mychannel", "Hello from .NET");

// Cache with expiration
await db.StringSetAsync("session:12345", "user_data", TimeSpan.FromMinutes(30));
```

**NuGet Paketi:**
```powershell
dotnet add package StackExchange.Redis
```

**ASP.NET Core Dependency Injection:**
```csharp
// Program.cs veya Startup.cs
using StackExchange.Redis;

builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var configuration = ConfigurationOptions.Parse("localhost:6379");
    configuration.Password = "redis_dev_password";
    return ConnectionMultiplexer.Connect(configuration);
});

// Controller'da kullanım
public class CacheController : ControllerBase
{
    private readonly IDatabase _redis;

    public CacheController(IConnectionMultiplexer redis)
    {
        _redis = redis.GetDatabase();
    }

    [HttpGet("{key}")]
    public async Task<IActionResult> Get(string key)
    {
        var value = await _redis.StringGetAsync(key);
        if (value.IsNullOrEmpty)
            return NotFound();
        
        return Ok(value.ToString());
    }

    [HttpPost]
    public async Task<IActionResult> Set(string key, string value)
    {
        await _redis.StringSetAsync(key, value, TimeSpan.FromHours(1));
        return Ok();
    }
}
```

##  Veri Kalıcılığı (Persistence)

Her ortam için ayrı named volumes kullanılır:

**Development:**
- `redis_dev_data` - Redis verileri
- `redisinsight_dev_data` - RedisInsight yapılandırması

**Test:**
- `redis_test_data`
- `redisinsight_test_data`

**Production:**
- `redis_prod_data`
- `redisinsight_prod_data`

### Volume Yönetimi

```powershell
# Tüm Redis volumes listele
docker volume ls | Select-String redis

# Belirli bir volume'u incele
docker volume inspect redis_dev_data

# Volume'u manuel sil (container durdurulmuş olmalı)
docker volume rm redis_dev_data
```

## �️ Güvenlik En İyi Pratikleri

### 1. Şifre Güvenliği
```powershell
# ❌ YANLIŞ - Zayıf şifre
REDIS_PASSWORD=123456

# ✅ DOĞRU - Güçlü şifre
REDIS_PASSWORD=Kx9&mP2$vL8@qR5#wN3!
```

### 2. Environment Ayrımı
- Development ve Test için basit şifreler kullanabilirsiniz
- Production için **mutlaka** güçlü, benzersiz şifreler kullanın
- Production şifrelerini asla development ile aynı yapmayın

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

### 5. Redis Güvenlik Ayarları
- Always use password authentication (`requirepass`)
- Disable dangerous commands in production (FLUSHALL, FLUSHDB, CONFIG)
- Use SSL/TLS for production connections
- Limit network access with firewall rules

## 📊 İzleme ve Bakım

### Container Durumunu Kontrol Etme

**Script ile:**
```powershell
.\manage.ps1 status dev redis
```

**Manuel:**
```powershell
# Tüm containerlar
docker ps

# Redis containerları
docker ps | Select-String "redis"

# Belirli bir ortam
Set-Location environments\dev
docker-compose ps

### Disk Kullanımı
```powershell
# Volume'leri listele
docker volume ls | Select-String redis

# Volume boyutunu kontrol et
docker system df -v
```

### Logları İnceleme

**Script ile:**
```powershell
# Canlı log izleme
.\manage.ps1 logs dev redis
```

**Manuel:**
```powershell
# Development ortamı
Set-Location environments\dev
docker-compose logs -f

# Son 100 satır
docker-compose logs --tail=100

# Belirli bir servisin logları
docker logs redis_dev
docker logs redisinsight_dev
```

### Backup Alma

```powershell
# Redis SAVE komutu ile backup
docker exec redis_dev redis-cli -a redis_dev_password SAVE

# RDB dosyasını kopyala
docker cp redis_dev:/data/dump.rdb "backup_dev_$(Get-Date -Format 'yyyyMMdd').rdb"

# Volume backup
docker run --rm -v redis_dev_data:/data -v $(pwd):/backup alpine tar czf /backup/redis_dev_backup.tar.gz /data

# Volume backup (Windows PowerShell)
docker run --rm -v redis_dev_data:/data -v ${PWD}:/backup alpine tar czf /backup/redis_dev_backup.tar.gz /data

# Restore etme
docker cp backup_dev_20260220.rdb redis_dev:/data/dump.rdb
docker-compose restart redis
```

## 🌐 Network İzolasyonu

Her ortam kendi network'ünde çalışır:
- `redis_dev_network`
- `redis_test_network`
- `redis_prod_network`

Bu sayede ortamlar birbirinden tamamen izoledir.

## 📱 RedisInsight Kullanımı

1. **Browser'da açın:**
   - Development: http://localhost:8001
   - Test: http://localhost:8002
   - Production: http://localhost:8003

2. **İlk Kurulum (First Run):**
   - "I agree" ile EULA'yı kabul edin
   - "Add Redis Database" butonuna tıklayın

3. **Redis Bağlantısı Ekleyin:**
   - **Host**: `redis` (container name - aynı network'te)
   - **Port**: `6379` (container içi port)
   - **Database Alias**: `Development` (veya istediğiniz isim)
   - **Username**: (boş bırakın)
   - **Password**: `.env` dosyasındaki `REDIS_PASSWORD`
   - "Add Redis Database" ile kaydedin

4. **RedisInsight Özellikleri:**
   - **Browser**: Key-value çiftlerini görüntüleme ve düzenleme
   - **Workbench**: Redis komutlarını interaktif çalıştırma
   - **Analysis Tools**: Memory analizi ve key pattern analizi
   - **Profiler**: Slow query monitoring
   - **CLI**: Built-in Redis CLI

5. **Manuel Host Bağlantısı (localhost üzerinden):**
   - Development için:
     - **Host**: `localhost`
     - **Port**: `6379`
     - **Password**: `.env` dosyasındaki `REDIS_PASSWORD`

## 🧪 Redis BağlanTı Testi

### Redis CLI ile Test (Container İçinden)

```powershell
# Development ortamı
docker exec -it redis_dev redis-cli -a redis_dev_password

# Test ortamı
docker exec -it redis_test redis-cli -a redis_test_password

# Production ortamı
docker exec -it redis_prod redis-cli -a redis_prod_password
```

### Örnek Redis Komutları

```redis
# Ping test
PING
# Response: PONG

# String operations
SET mykey "Hello Redis"
GET mykey
INCR counter
DECR counter
APPEND mykey " World"

# Key management
KEYS *                  # Tüm keys (production'da dikkatli kullanın!)
SCAN 0 MATCH user:*     # Pattern ile key arama (daha güvenli)
EXISTS mykey
DEL mykey
EXPIRE mykey 3600       # 1 saat TTL
TTL mykey

# Hash operations
HSET user:1000 name "John Doe" email "john@example.com"
HGET user:1000 name
HGETALL user:1000
HDEL user:1000 email

# List operations
LPUSH mylist "item1"
LPUSH mylist "item2"
LRANGE mylist 0 -1
RPOP mylist

# Set operations
SADD myset "member1"
SADD myset "member2"
SMEMBERS myset
SISMEMBER myset "member1"

# Sorted Set operations
ZADD leaderboard 100 "player1"
ZADD leaderboard 200 "player2"
ZRANGE leaderboard 0 -1 WITHSCORES
ZREVRANGE leaderboard 0 9 WITHSCORES  # Top 10

# Database bilgisi
INFO
INFO memory
INFO stats
INFO replication
DBSIZE
CONFIG GET maxmemory

# Client yönetimi
CLIENT LIST
CLIENT SETNAME "my-application"

# Performance monitoring
SLOWLOG GET 10
MONITOR  # Real-time komut izleme (dikkatli kullanın!)

# Persistence
SAVE         # Synchronous save
BGSAVE       # Background save
LASTSAVE     # Son save zamanı
```

### Host'tan Bağlantı Testi

```powershell
# redis-cli yüklüyse Windows'ta
redis-cli -h localhost -p 6379 -a redis_dev_password PING

# PowerShell ile Test-NetConnection
Test-NetConnection -ComputerName localhost -Port 6379
```

## 🔍 Sorun Giderme

### Port Zaten Kullanılıyor

```powershell
netstat -ano | findstr :6379
```
Çözüm: İlgili ortamın `.env` dosyasında `REDIS_PORT` değerini değiştirin.

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

### RedisInsight Bağlanamıyor

```powershell
# Redis container'ının hazır olup olmadığını kontrol et
docker exec redis_dev redis-cli -a redis_dev_password PING

# Network bağlantısını kontrol et
docker network inspect redis_dev_network

# RedisInsight'i yeniden başlat
Set-Location environments\dev
docker-compose restart redisinsight
```

### Redis Verileri Kayboldu

```powershell
# 1. Backup aldıysanız restore edin
# 2. Volume durumunu kontrol edin
docker volume inspect redis_dev_data

# 3. Redis loglarını kontrol edin
docker logs redis_dev

# 4. Yoksa temizleyip yeniden başlatın
.\manage.ps1 clean dev redis
.\manage.ps1 start dev redis
```

### Script Çalışmıyor (Windows)

```powershell
# PowerShell execution policy sorunuysa
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Sonra tekrar deneyin
.\manage.ps1 start dev
```

## 🔄 Güncelleme ve Bakım

### Redis Versiyonunu Güncelleme

1. İlgili ortamın `docker-compose.yml` dosyasını düzenleyin:
```yaml
image: redis:8-alpine  # 7-alpine yerine
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
.\manage.ps1 clean dev redis

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
8. **AOF persistence** kullanarak veri kaybını önleyin
9. **Redis memory limit** ayarlayın production için
10. **Monitoring** ekleyin, RedisInsight'tan metrik takibi yapın

## 🎯 Ortamlar Arası Geçiş

```powershell
# Development'tan Test'e geçiş
.\manage.ps1 stop dev redis
.\manage.ps1 start test redis

# Sadece Production
.\manage.ps1 stop dev redis
.\manage.ps1 stop test redis
.\manage.ps1 start prod redis
```

## 🔍 Örnek Senaryolar

### Senaryo 1: Yeni Proje Başlangıcı

```powershell
# 1. Şifreleri güncelle
code environments/dev/.env

# 2. Development ortamını başlat
.\manage.ps1 start dev redis

# 3. RedisInsight'a giriş yap
# http://localhost:8001

# 4. Çalışmayı bitirince durdur
.\manage.ps1 stop dev redis
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
.\manage.ps1 start prod redis

# 3. Health check
docker ps | Select-String prod

# 4. Logları kontrol et
.\manage.ps1 logs prod redis

# 5. Redis bağlantı testi
docker exec redis_prod redis-cli -a <prod_password> PING
```

### Senaryo 4: Cache Kullanımı

```powershell
# Development başlat
.\manage.ps1 start dev redis

# .NET ile bağlan ve cache kullan
# using StackExchange.Redis;
var redis = ConnectionMultiplexer.Connect("localhost:6379,password=redis_dev_password");
var db = redis.GetDatabase();
db.StringSet("user:1000", "John Doe", TimeSpan.FromHours(1)); // 1 saat cache
Console.WriteLine(db.StringGet("user:1000"));
```

## 📚 Ek Kaynaklar

- [Redis Resmi Dokümantasyon](https://redis.io/documentation)
- [Redis Commands Reference](https://redis.io/commands)
- [RedisInsight Dokümantasyon](https://redis.io/docs/stack/insight/)
- [Docker Compose Referans](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
- [Redis Security](https://redis.io/docs/management/security/)

## ❓ Sık Sorulan Sorular

**S: Neden her ortam için ayrı klasör?**
A: İzolasyon, bağımsızlık ve karışıklığı önlemek için. Her ortam kendi bağımsız ekosisteminde çalışır.

**S: Tüm ortamları aynı anda çalıştırabilir miyim?**
A: Evet, her ortam farklı portlarda olduğu için sorunsuzca çalışabilir.

**S: AOF (Append Only File) nedir?**
A: Redis'in veri kalıcılığı mekanizmasıdır. Her yazma işlemi bir dosyaya kaydedilir, böylece restart sonrası veriler korunur.

**S: RedisInsight nedir ve neden kullanmalıyım?**
A: Redis için modern bir GUI aracıdır. Veri görselleştirme, query çalıştırma ve monitoring için kullanılır.

**S: Production'da restart policy neden "unless-stopped"?**
A: Container manuel olarak durdurulana kadar sürekli çalışmasını sağlar. Sunucu yeniden başladığında otomatik başlar.

**S: Redis şifresiz çalışabilir mi?**
A: Evet ama **asla production'da şifresiz çalıştırmayın**. Development için bile şifre kullanmanızı öneririz.

**S: Redis Memory Limit nasıl ayarlanır?**
A: docker-compose.yml'de `command` kısmına `--maxmemory 256mb --maxmemory-policy allkeys-lru` ekleyin.

## 🤝 Katkıda Bulunma

Bu proje template olarak kullanılabilir. İyileştirme önerileri:
- Ek monitoring araçları (Prometheus, AlertManager)
- Otomatik backup scriptleri
- CI/CD entegrasyonu
- Kubernetes manifests
- Redis Cluster yapılandırması
- Redis Sentinel için high availability

## 📄 Lisans

Bu proje özgür kullanım içindir. İstediğiniz gibi kullanabilir, değiştirebilir ve dağıtabilirsiniz.

## ✅ Kontrol Listesi

Kurulum sonrası kontrol:

- [ ] Tüm container'lar çalışıyor mu? (`docker-compose ps`)
- [ ] Redis'e bağlanabiliyor musunuz? (`redis-cli`)
- [ ] RedisInsight açılıyor mu? (http://localhost:8001)
- [ ] Şifreler değiştirildi mi? (Production için)
- [ ] Firewall kuralları ayarlandı mı? (Production için)
- [ ] Backup stratejisi belirlendi mi?
- [ ] AOF persistence çalışıyor mu?
- [ ] Memory limit ayarlandı mı? (Production için)

## 🎯 Sonraki Adımlar

1. **Monitoring**: RedisInsight dashboard'larını yapılandırın
2. **Alerting**: Kritik metrikler için alert kuralları ekleyin (memory, connection count)
3. **Backup**: Otomatik backup scriptleri oluşturun (cron job)
4. **Documentation**: Özel kullanım senaryolarınızı belgeleyin
5. **Security**: Production şifrelerini ve network kurallarını gözden geçirin
6. **Performance**: Redis configurasyon ayarlarını optimize edin
7. **Scaling**: Gerekirse Redis Cluster veya Sentinel ekleyin

---

**Hazırlayan**: Docker Redis Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
