# MongoDB + Mongo Express Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment MongoDB + Mongo Express kurulumu.

## 📁 Klasör Yapısı

```
mongodb/
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

- ✅ **MongoDB 7**: Latest stable NoSQL document database
- ✅ **Mongo Express**: Web-based admin interface
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Güvenli**: Authentication enabled, .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Persistence**: Volume'ler ile veri kalıcılığı
- ✅ **Health Checks**: Container durumu otomatik kontrol

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item mongodb\environments\dev\.env.example mongodb\environments\dev\.env
Copy-Item mongodb\environments\test\.env.example mongodb\environments\test\.env
Copy-Item mongodb\environments\prod\.env.example mongodb\environments\prod\.env
```

**Güvenlik için şifreleri değiştirin:**

```powershell
# environments/dev/.env
MONGO_INITDB_ROOT_PASSWORD=güçlü_dev_şifresi
MONGOEXPRESS_PASSWORD=güçlü_mongoexpress_şifresi

# environments/test/.env
MONGO_INITDB_ROOT_PASSWORD=güçlü_test_şifresi
MONGOEXPRESS_PASSWORD=güçlü_mongoexpress_şifresi

# environments/prod/.env
MONGO_INITDB_ROOT_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
MONGOEXPRESS_PASSWORD=ÇOK_GÜÇLÜ_MONGOEXPRESS_ŞİFRESİ_456!@#
```

### 2️⃣ Ortamı Başlatma

**Yönetim Scripti (Önerilen):**

```powershell
# Windows PowerShell
.\manage.ps1 start dev mongodb
```

### 3️⃣ Erişim

| Ortam | MongoDB `→27017` | Mongo Express `→8081` |
|-------|------------------|----------------------|
| **Dev** | `localhost:27017` | http://localhost:8081 |
| **Test** | `localhost:27018` | http://localhost:8082 |
| **Prod** | `localhost:27019` | http://localhost:8083 |

> Mongo Express giriş bilgileri: `.env` dosyasındaki `MONGOEXPRESS_LOGIN` / `MONGOEXPRESS_PASSWORD`

## 📋 Komutlar

### Yönetim Scripti ile

```powershell
# Başlatma
.\manage.ps1 start dev mongodb
.\manage.ps1 start test mongodb
.\manage.ps1 start prod mongodb

# Durdurma
.\manage.ps1 stop dev mongodb

# Yeniden başlatma
.\manage.ps1 restart dev mongodb

# Logları görüntüleme
.\manage.ps1 logs dev mongodb

# Durum kontrolü
.\manage.ps1 status dev mongodb

# Temizleme (TÜM VERİLER SİLİNİR!)
.\manage.ps1 clean dev mongodb
```

### Manuel Docker Compose Komutları

```powershell
# Ortama git
Set-Location mongodb\environments\dev

# Başlat
docker-compose up -d

# Durdur
docker-compose down

# Logları göster
docker-compose logs -f

# Durum kontrol
docker-compose ps

# Yeniden başlat
docker-compose restart

# Temizle (volumes dahil)
docker-compose down -v
```

## 🔧 Yapılandırma

### Port Dağılımı

| Ortam       | MongoDB | Mongo Express |
|-------------|---------|---------------|
| Development | 27017   | 8081          |
| Test        | 27018   | 8082          |
| Production  | 27019   | 8083          |

### Ortam Değişkenleri

```env
# MongoDB Settings
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=your_password_here
MONGO_PORT=27017

# Mongo Express Settings
MONGOEXPRESS_LOGIN=admin
MONGOEXPRESS_PASSWORD=your_mongoexpress_password
MONGOEXPRESS_PORT=8081
```

## 💾 Veri Yönetimi

### Volume'ler

Her ortamın kendine ait volume'leri var:

```
mongodb_dev_data          # Dev verileri
mongodb_dev_config        # Dev config
mongodb_test_data         # Test verileri
mongodb_test_config       # Test config
mongodb_prod_data         # Prod verileri
mongodb_prod_config       # Prod config
```

### Backup

```powershell
# Backup oluşturma
docker exec mongodb_dev mongodump --username admin --password your_password --authenticationDatabase admin --out /data/backup

# Container'dan backup'ı kopyalama
docker cp mongodb_dev:/data/backup ./backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')
```

### Restore

```powershell
# Backup'ı container'a kopyalama
docker cp ./backup_folder mongodb_dev:/data/restore

# Restore etme
docker exec mongodb_dev mongorestore --username admin --password your_password --authenticationDatabase admin /data/restore
```

## 🔐 Güvenlik

### Öncelikli Güvenlik Adımları

1. **Şifreleri Değiştirin**: Varsayılan şifreleri asla kullanmayın
2. **Güçlü Şifreler**: Minimum 16 karakter, karışık karakterler
3. **Production İçin**: Ekstra güçlü şifreler ve firewall kuralları
4. **Network İzolasyonu**: Her ortam kendi network'ünde

### Connection String Formatı

```
# Temel bağlantı
mongodb://username:password@host:port/database

# Authentication database belirterek
mongodb://admin:password@localhost:27017/mydb?authSource=admin

# Örnek connection string
mongodb://admin:your_password@localhost:27017/myapp?authSource=admin
```

## � .NET Core Örnek Kullanım

**NuGet Paketi:**
```powershell
dotnet add package MongoDB.Driver
```

### Typed POCO Model ile Temel Kullanım

```csharp
using MongoDB.Driver;

// Model tanımı
public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int Age { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// Bağlantı ve CRUD
var client = new MongoClient("mongodb://admin:password@localhost:27017");
var database = client.GetDatabase("myapp");
var collection = database.GetCollection<User>("users");

// Insert
var newUser = new User { Name = "John Doe", Email = "john@example.com", Age = 30 };
await collection.InsertOneAsync(newUser);
Console.WriteLine($"Inserted Id: {newUser.Id}");

// Bulk Insert
var users = new List<User>
{
    new User { Name = "Alice", Email = "alice@example.com", Age = 25 },
    new User { Name = "Bob",   Email = "bob@example.com",   Age = 35 }
};
await collection.InsertManyAsync(users);

// Find
var filter = Builders<User>.Filter.Gt(u => u.Age, 25);
var result = await collection.Find(filter).ToListAsync();
foreach (var user in result)
    Console.WriteLine($"{user.Name} - {user.Email}");

// Find One
var singleUser = await collection.Find(u => u.Email == "john@example.com").FirstOrDefaultAsync();

// Update
var update = Builders<User>.Update.Set(u => u.Age, 31);
await collection.UpdateOneAsync(u => u.Email == "john@example.com", update);

// Delete
await collection.DeleteOneAsync(u => u.Email == "john@example.com");

// Count
var count = await collection.CountDocumentsAsync(Builders<User>.Filter.Empty);
Console.WriteLine($"Toplam kullanıcı: {count}");
```

### ASP.NET Core Dependency Injection

```csharp
// Program.cs
builder.Services.AddSingleton<IMongoClient>(sp =>
    new MongoClient("mongodb://admin:password@localhost:27017"));

builder.Services.AddScoped<IMongoDatabase>(sp =>
    sp.GetRequiredService<IMongoClient>().GetDatabase("myapp"));

// Repository katmanı
public class UserRepository
{
    private readonly IMongoCollection<User> _collection;

    public UserRepository(IMongoDatabase database)
    {
        _collection = database.GetCollection<User>("users");
    }

    public async Task<List<User>> GetAllAsync() =>
        await _collection.Find(Builders<User>.Filter.Empty).ToListAsync();

    public async Task<User?> GetByIdAsync(string id) =>
        await _collection.Find(u => u.Id == id).FirstOrDefaultAsync();

    public async Task CreateAsync(User user) =>
        await _collection.InsertOneAsync(user);

    public async Task UpdateAsync(string id, User updatedUser) =>
        await _collection.ReplaceOneAsync(u => u.Id == id, updatedUser);

    public async Task DeleteAsync(string id) =>
        await _collection.DeleteOneAsync(u => u.Id == id);
}

// Service kaydı
builder.Services.AddScoped<UserRepository>();
```

## 🔍 Sorun Giderme

### MongoDB bağlantı hatası

```powershell
# Container loglarını kontrol edin
docker logs mongodb_dev

# Health check durumu
docker inspect mongodb_dev --format='{{.State.Health.Status}}'
```

### Mongo Express açılmıyor

```powershell
# Mongo Express logları
docker logs mongoexpress_dev

# MongoDB'nin healthy olduğundan emin olun
docker ps
```

### Port çakışması

```powershell
# Kullanılan portları kontrol edin
netstat -ano | findstr :27017

# .env dosyasında farklı port ayarlayın
MONGO_PORT=27020
```

## 📊 Monitoring

### Container Durumu

```powershell
# Tüm MongoDB container'ları
docker ps -a | findstr mongodb

# Belirli ortam
docker-compose -f mongodb/environments/dev/docker-compose.yml ps
```

### Resource Kullanımı

```powershell
# CPU ve Memory kullanımı
docker stats mongodb_dev mongoexpress_dev

# Disk kullanımı
docker system df -v | findstr mongodb
```

## 🎯 Best Practices

1. **Development**: Test ve geliştirme için özgürce kullanın
2. **Test**: Production benzeri veri ile test edin
3. **Production**: 
   - Regular backups alın
   - Strong authentication kullanın
   - Resource limits belirleyin
   - Monitoring ekleyin

## 📚 Ek Kaynaklar

- [MongoDB Documentation](https://docs.mongodb.com/)
- [Mongo Express GitHub](https://github.com/mongo-express/mongo-express)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/administration/production-notes/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

## 🆘 Destek

Sorun yaşıyorsanız:

1. Container loglarını kontrol edin
2. Network bağlantısını kontrol edin
3. .env dosyası ayarlarını gözden geçirin
4. Port çakışması olmadığından emin olun
---

**Hazırlayan:** Docker MongoDB Multi-Environment Setup  
**Son Güncelleme:** 2026-02-21  
**Versiyon:** 1.0.0