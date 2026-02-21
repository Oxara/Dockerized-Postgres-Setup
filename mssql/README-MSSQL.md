# MSSQL (SQL Server) Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment **SQL Server 2022** + **Adminer** kurulumu.

## 📁 Klasör Yapısı

```
mssql/
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

- ✅ **SQL Server 2022**: En güncel LTS sürüm, Linux container ile Windows'ta çalışır
- ✅ **Adminer Web UI**: Browser tabanlı veritabanı yönetim arayüzü
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Güvenli**: .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Veri Kalıcılığı**: Docker volumes ile veri persistence
- ✅ **Health Checks**: Hazır olmadan önce servisler bekler

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

```powershell
# .env.example dosyasından .env oluştur
Copy-Item mssql\environments\dev\.env.example mssql\environments\dev\.env

# Şifreleri düzenle (zorunlu - SQL Server güçlü şifre gerektirir!)
# Min 8 karakter: büyük harf + küçük harf + rakam + özel karakter
notepad mssql\environments\dev\.env
```

> ⚠️ **SQL Server Şifre Gereksinimleri**: SA şifresi mutlaka karmaşıklık gereksinimlerini karşılamalıdır!  
> En az 8 karakter, büyük harf, küçük harf, rakam ve özel karakter içermelidir.

### 2️⃣ Başlatma

```powershell
# manage.ps1 ile (önerilen)
Set-Location C:\Projects\Docker-Service-Stack
.\manage.ps1 start dev mssql

# veya doğrudan docker-compose ile
Set-Location mssql\environments\dev
docker-compose -p mssql_dev up -d
```

### 3️⃣ Erişim

| Ortam | SQL Server `→1433` | Adminer `→8080` |
|-------|------------------|-----------------|
| **Dev** | `localhost,1433` | http://localhost:8380 |
| **Test** | `localhost,1434` | http://localhost:8381 |
| **Prod** | `localhost,1435` | http://localhost:8382 |

**Adminer:** Sistem `MS SQL` · Server `mssql` · Login `sa` · Şifre: `.env` → `MSSQL_SA_PASSWORD`  
**SSMS / Azure Data Studio:** Auth `SQL Server Authentication` · Login `sa`

### 4️⃣ Durdurma

```powershell
.\manage.ps1 stop dev mssql
```

##  Yapılandırma

### .env Değişkenleri

| Değişken | Açıklama | Varsayılan (Dev) |
|----------|----------|-----------------|
| `MSSQL_SA_PASSWORD` | SA kullanıcısı şifresi (**karmaşık olmalı!**) | `Mssql_Dev_P@ssw0rd!` |
| `MSSQL_PID` | SQL Server edition (Developer / Standard / Enterprise) | `Developer` |
| `MSSQL_PORT` | SQL Server portu | `1433` |
| `ADMINER_PORT` | Adminer web UI portu | `8380` |

### SQL Server Edition Seçimi

```dotenv
# Developer (ücretsiz, production'da kullanılamaz - tüm özellikler)
MSSQL_PID=Developer

# Express (ücretsiz, production'da kullanılabilir - 10GB limit)
MSSQL_PID=Express

# Standard (lisanslı)
MSSQL_PID=Standard

# Enterprise (lisanslı)
MSSQL_PID=Enterprise
```

## 💻 .NET Core Kullanım Örnekleri

### NuGet Paketi

```powershell
dotnet add package Microsoft.Data.SqlClient
# EF Core için:
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

### Connection String Yapısı

```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=MyAppDb;User Id=sa;Password=Mssql_Dev_P@ssw0rd!;TrustServerCertificate=True;"
  }
}
```

> 💡 `TrustServerCertificate=True` geliştirme ortamında self-signed sertifikayı kabul eder.

### Entity Framework Core ile Kullanım

```csharp
// Program.cs
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
```

```csharp
// AppDbContext.cs
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }
}
```

```csharp
// Models/Product.cs
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

### Migration ve Veritabanı Oluşturma

```powershell
# Migration oluştur
dotnet ef migrations add InitialCreate

# Veritabanını oluştur / güncelle
dotnet ef database update

# Migration script oluştur (production için)
dotnet ef migrations script -o migration.sql
```

### CRUD Operasyonları (EF Core)

```csharp
public class ProductService
{
    private readonly AppDbContext _context;

    public ProductService(AppDbContext context) => _context = context;

    // Kayıt ekle
    public async Task<Product> CreateAsync(Product product)
    {
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return product;
    }

    // ID ile getir
    public async Task<Product?> GetByIdAsync(int id)
        => await _context.Products.FindAsync(id);

    // Filtreleme ve listeleme
    public async Task<List<Product>> GetAllAsync(decimal? maxPrice = null)
    {
        var query = _context.Products.AsQueryable();

        if (maxPrice.HasValue)
            query = query.Where(p => p.Price <= maxPrice.Value);

        return await query.OrderBy(p => p.Name).ToListAsync();
    }

    // Güncelleme
    public async Task<bool> UpdateAsync(int id, Product updated)
    {
        var product = await _context.Products.FindAsync(id);
        if (product is null) return false;

        product.Name  = updated.Name;
        product.Price = updated.Price;
        product.Stock = updated.Stock;

        await _context.SaveChangesAsync();
        return true;
    }

    // Silme
    public async Task<bool> DeleteAsync(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product is null) return false;

        _context.Products.Remove(product);
        await _context.SaveChangesAsync();
        return true;
    }
}
```

### Ham SQL Sorguları (EF Core)

```csharp
// Ham SQL sorgusu - Entity döndüren
var products = await _context.Products
    .FromSqlRaw("SELECT * FROM Products WHERE Price > {0}", 100m)
    .ToListAsync();

// Ham SQL - scalar değer
var count = await _context.Database
    .ExecuteSqlRawAsync("UPDATE Products SET Stock = Stock - 1 WHERE Id = {0}", productId);

// Stored procedure çağırma
var result = await _context.Products
    .FromSqlRaw("EXEC GetProductsByCategory @CategoryId = {0}", categoryId)
    .ToListAsync();
```

### Microsoft.Data.SqlClient ile Doğrudan Bağlantı

```csharp
using Microsoft.Data.SqlClient;

var connectionString = "Server=localhost,1433;Database=MyAppDb;User Id=sa;" +
                       "Password=Mssql_Dev_P@ssw0rd!;TrustServerCertificate=True;";

await using var connection = new SqlConnection(connectionString);
await connection.OpenAsync();

// Parametreli sorgu
var command = new SqlCommand(
    "SELECT Id, Name, Price FROM Products WHERE Stock > @minStock",
    connection);
command.Parameters.AddWithValue("@minStock", 0);

await using var reader = await command.ExecuteReaderAsync();
while (await reader.ReadAsync())
{
    Console.WriteLine($"Id: {reader.GetInt32(0)}, Name: {reader.GetString(1)}, Price: {reader.GetDecimal(2)}");
}
```

### ASP.NET Core Repository Pattern

```csharp
// Interfaces/IProductRepository.cs
public interface IProductRepository
{
    Task<Product?> GetByIdAsync(int id);
    Task<IEnumerable<Product>> GetAllAsync();
    Task AddAsync(Product product);
    Task UpdateAsync(Product product);
    Task DeleteAsync(int id);
}

// Repositories/ProductRepository.cs
public class ProductRepository : IProductRepository
{
    private readonly AppDbContext _context;

    public ProductRepository(AppDbContext context) => _context = context;

    public Task<Product?> GetByIdAsync(int id)
        => _context.Products.FindAsync(id).AsTask();

    public Task<IEnumerable<Product>> GetAllAsync()
        => _context.Products.OrderBy(p => p.Name).ToListAsync()
            .ContinueWith(t => (IEnumerable<Product>)t.Result);

    public async Task AddAsync(Product product)
    {
        await _context.Products.AddAsync(product);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product is not null)
        {
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
        }
    }
}

// Program.cs
builder.Services.AddScoped<IProductRepository, ProductRepository>();
```

## 🗄️ Veritabanı Yönetimi

### SQL Server Management Studio (SSMS) ile Bağlantı

1. SSMS'i açın
2. Server name: `localhost,1433`
3. Authentication: SQL Server Authentication
4. Login / Password: `.env` dosyasına göre

### Yeni Kullanıcı Oluşturma (SA Kullanmaktan Kaçının)

```sql
-- Yeni login oluştur
CREATE LOGIN myapp_user WITH PASSWORD = 'StrongPassword123!';

-- Veritabanı kullanıcısı oluştur
USE MyAppDb;
CREATE USER myapp_user FOR LOGIN myapp_user;

-- İzinler ver
ALTER ROLE db_datareader ADD MEMBER myapp_user;
ALTER ROLE db_datawriter ADD MEMBER myapp_user;
```

### Backup ve Restore

```powershell
# Backup al
docker exec mssql_dev /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "YourPassword123!" `
    -Q "BACKUP DATABASE [MyAppDb] TO DISK='/var/opt/mssql/backup/myapp.bak' WITH FORMAT" `
    -No

# Backup dosyasını host'a kopyala
docker cp mssql_dev:/var/opt/mssql/backup/myapp.bak C:\Backups\myapp.bak

# Restore
docker exec mssql_dev /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "YourPassword123!" `
    -Q "RESTORE DATABASE [MyAppDb] FROM DISK='/var/opt/mssql/backup/myapp.bak' WITH REPLACE" `
    -No
```

## 🔍 Sorun Giderme

### Container Başlamıyor

```powershell
# Logları kontrol et
.\manage.ps1 logs dev mssql

# Yaygın nedenler:
# 1. Şifre karmaşıklık gereksinimini karşılamıyor
# 2. Port 1433 zaten kullanımda
# 3. Yetersiz RAM (SQL Server min ~2GB RAM gerektirir)
```

### Şifre Hatası

```powershell
# SQL Server şifre gereksinimleri:
# - En az 8 karakter
# - Büyük harf (A-Z)
# - Küçük harf (a-z)
# - Rakam (0-9)
# - Özel karakter (!@#$%^&* vb.)

# Geçerli örnek: MyP@ssw0rd2024!
```

### Port Çakışması

```powershell
# Portu kontrol et
netstat -ano | findstr :1433

# .env dosyasında portu değiştir
# MSSQL_PORT=1433  →  MSSQL_PORT=1444
```

### EF Core Bağlantı Hatası

```
SqlException: Cannot open server 'localhost,1433' requested by the login
```

```csharp
// TrustServerCertificate=True ekleyin
"Server=localhost,1433;Database=MyAppDb;User Id=sa;Password=...;TrustServerCertificate=True;"
```

### Container İçinde sqlcmd Kullanımı

```powershell
# SQL Server container'a bağlan
docker exec -it mssql_dev /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "YourPassword123!" -No

# Veritabanları listele
SELECT name FROM sys.databases;
GO

# Bağlantıyı kapat
QUIT
```

## 🔒 Güvenlik Notları

### Development/Test
- SA hesabı kullanılabilir ancak production için önerilmez
- `TrustServerCertificate=True` sadece dev/test için kullanın
- Developer/Express edition production'da kullanılamaz

### Production
- **SA şifresini mutlaka değiştirin** (en az 20 karakter)
- Uygulama için ayrı, kısıtlı yetki ile yeni login oluşturun
- SA hesabını devre dışı bırakın
- SSL sertifikası yapılandırın
- Firewall ile 1435 portunu kısıtlayın

## ✅ Production Kontrol Listesi

- [ ] MSSQL_SA_PASSWORD güçlü şifre ile güncellendi mi?
- [ ] Uygulama için SA olmayan ayrı kullanıcı oluşturuldu mu?
- [ ] MSSQL_PID=Standard veya Enterprise ayarlandı mı?
- [ ] Port erişimi güvenlik duvarı ile kısıtlandı mı?
- [ ] Otomatik backup stratejisi belirlendi mi?
- [ ] .env dosyası Git'e yüklenmiyor mu?

## 🎯 Sonraki Adımlar

1. **EF Core Migrations**: Şema yönetim stratejisi belirleyin
2. **Connection Pooling**: `Max Pool Size` ayarlarını optimize edin
3. **Index Yönetimi**: Sorgu performansı için index stratejisi oluşturun
4. **Backup Otomasyonu**: Windows Task Scheduler ile otomatik backup
5. **Monitoring**: Prometheus SQL Server exporter ekleyin
6. **Always Encrypted**: Hassas veriler için sütun şifreleme

---

**Hazırlayan**: Docker MSSQL Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Ana dokümantasyon: [README.md](README.md)  
🔴 MSSQL Detayları: [README-MSSQL.md](README-MSSQL.md)  
📘 PostgreSQL Detayları: [README-PostgreSQL.md](README-PostgreSQL.md)  
📕 Redis Detayları: [README-Redis.md](README-Redis.md)  
📙 RabbitMQ Detayları: [README-RabbitMQ.md](README-RabbitMQ.md)  
📗 Elasticsearch Detayları: [README-Elasticsearch.md](README-Elasticsearch.md)  
🍃 MongoDB Detayları: [README-MongoDB.md](README-MongoDB.md)  
📊 Monitoring Detayları: [README-Monitoring.md](README-Monitoring.md)  
🔐 Keycloak Detayları: [README-Keycloak.md](README-Keycloak.md)  
📋 Seq Detayları: [README-Seq.md](README-Seq.md)  
📧 MailHog Detayları: [README-MailHog.md](README-MailHog.md)

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
