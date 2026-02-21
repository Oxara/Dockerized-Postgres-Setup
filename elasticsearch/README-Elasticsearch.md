# Elasticsearch + Kibana Multi-Environment Docker Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment Elasticsearch + Kibana kurulumu.

## 📁 Klasör Yapısı

```
elasticsearch/
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
- ✅ **Kibana UI**: Web tabanlı görselleştirme ve yönetim
- ✅ **Persistence**: Volume'ler ile veri kalıcılığı
- ✅ **X-Pack Security**: Built-in güvenlik özellikleri

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item elasticsearch\environments\dev\.env.example elasticsearch\environments\dev\.env
Copy-Item elasticsearch\environments\test\.env.example elasticsearch\environments\test\.env
Copy-Item elasticsearch\environments\prod\.env.example elasticsearch\environments\prod\.env
```

**Her ortam için portlar zaten ayarlı:**

- **Dev:** `ELASTIC_PORT=9200`, `KIBANA_PORT=5601`
- **Test:** `ELASTIC_PORT=9201`, `KIBANA_PORT=5602`
- **Prod:** `ELASTIC_PORT=9202`, `KIBANA_PORT=5603`

**Güvenlik için şifreleri değiştirin:**

```powershell
# environments/dev/.env
ELASTIC_PASSWORD=güçlü_dev_şifresi

# environments/test/.env
ELASTIC_PASSWORD=güçlü_test_şifresi

# environments/prod/.env
ELASTIC_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
```

### 2️⃣ Ortamı Başlatma

**Yönetim Scripti (Önerilen):**

```powershell
# Windows PowerShell
.\manage.ps1 start dev elasticsearch
```

### 3️⃣ Erişim

| Ortam | Elasticsearch API `→9200` | Kibana UI `→5601` |
|-------|---------------------------|------------------|
| **Dev** | http://localhost:9200 | http://localhost:5601 |
| **Test** | http://localhost:9201 | http://localhost:5602 |
| **Prod** | http://localhost:9202 | http://localhost:5603 |

**Kimlik Bilgileri:**
- **Username**: `elastic`
- **Password**: `.env` dosyasındaki `ELASTIC_PASSWORD`

## 📖 Kullanım Kılavuzu

### Yönetim Scriptleri

```powershell
# BAŞLATMA
.\manage.ps1 start dev elasticsearch      # Development başlat
.\manage.ps1 start test elasticsearch     # Test başlat
.\manage.ps1 start prod elasticsearch     # Production başlat

# DURDURMA
.\manage.ps1 stop dev elasticsearch       # Development durdur
.\manage.ps1 stop test elasticsearch      # Test durdur

# YENİDEN BAŞLATMA
.\manage.ps1 restart dev elasticsearch    # Development yeniden başlat

# LOGLARI İZLEME
.\manage.ps1 logs dev elasticsearch       # Development logları (Ctrl+C ile çık)

# DURUM KONTROLÜ
.\manage.ps1 status dev elasticsearch     # Development durumu
.\manage.ps1 status prod elasticsearch    # Production durumu

# TEMİZLEME (VERİLER SİLİNİR!)
.\manage.ps1 clean dev elasticsearch      # Development ortamını temizle
```

## 🔧 Yapılandırma

Her ortamın kendi `.env` dosyası vardır:

**environments/dev/.env:**
```env
# Elasticsearch Settings
ELASTIC_PASSWORD=güçlü_şifre_buraya
ELASTIC_PORT=9200

# Kibana Settings
KIBANA_PORT=5601
```

### Port Yapılandırması

Default portlar:
- **Dev**: Elasticsearch 9200, Kibana 5601
- **Test**: Elasticsearch 9201, Kibana 5602
- **Prod**: Elasticsearch 9202, Kibana 5603

## 🔌 Elasticsearch'e Bağlanma

### Kibana UI'dan Erişim

1. Kibana'ya giriş yapın (http://localhost:5601 - dev için)
2. İlk açılışta kullanıcı adı ve şifre ile giriş yapın:
   - **Username**: `elastic`
   - **Password**: `.env` dosyasındaki `ELASTIC_PASSWORD`

### Kibana UI Özellikleri

- **Discover**: Index pattern oluşturma ve veri keşfi
- **Visualize**: Grafikler ve görselleştirmeler
- **Dashboard**: Görselleştirmeleri dashboard'da birleştirme
- **Dev Tools**: Console ile Elasticsearch sorguları çalıştırma
- **Stack Management**: Index, user ve ayar yönetimi

### REST API ile Bağlanma

**Temel Kontrol:**
```powershell
# Cluster health
$cred = Get-Credential -UserName "elastic" -Message "Enter password"
Invoke-RestMethod -Uri "http://localhost:9200/_cluster/health?pretty" -Credential $cred

# Veya Basic Auth ile
$password = "your_password"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("elastic:{0}" -f $password)))
Invoke-RestMethod -Uri "http://localhost:9200/_cat/nodes?v" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# Index listesi
Invoke-RestMethod -Uri "http://localhost:9200/_cat/indices?v" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
```

### .NET Core Örneği (NEST)

```csharp
using Nest;

// Bağlantı oluştur
var settings = new ConnectionSettings(new Uri("http://localhost:9200"))
    .BasicAuthentication("elastic", "your_password")
    .DefaultIndex("test-index");

var client = new ElasticClient(settings);

// Cluster bilgisi
var clusterInfo = await client.PingAsync();
Console.WriteLine($"Cluster is healthy: {clusterInfo.IsValid}");

// Index oluştur
var createIndexResponse = await client.Indices.CreateAsync("test-index", c => c
    .Map<Document>(m => m
        .Properties(p => p
            .Text(t => t.Name(n => n.Author))
            .Text(t => t.Name(n => n.Text))
            .Date(d => d.Name(n => n.Timestamp))
        )
    )
);

// Döküman sınıfı
public class Document
{
    public string Author { get; set; }
    public string Text { get; set; }
    public DateTime Timestamp { get; set; }
}

// Döküman ekle
var doc = new Document
{
    Author = "John Doe",
    Text = "Elasticsearch is awesome from .NET!",
    Timestamp = DateTime.UtcNow
};

var indexResponse = await client.IndexAsync(doc, idx => idx
    .Index("test-index")
    .Id("1")
);

Console.WriteLine($"Indexed: {indexResponse.IsValid}");

// Bulk insert örneği
var documents = new List<Document>
{
    new Document { Author = "Alice", Text = "Learning Elasticsearch", Timestamp = DateTime.UtcNow },
    new Document { Author = "Bob", Text = "NEST is great", Timestamp = DateTime.UtcNow },
    new Document { Author = "Charlie", Text = "Searching with .NET", Timestamp = DateTime.UtcNow }
};

var bulkResponse = await client.BulkAsync(b => b
    .Index("test-index")
    .IndexMany(documents)
);

// Döküman ara
var searchResponse = await client.SearchAsync<Document>(s => s
    .Index("test-index")
    .Query(q => q
        .Match(m => m
            .Field(f => f.Text)
            .Query("elasticsearch")
        )
    )
);

foreach (var hit in searchResponse.Hits)
{
    Console.WriteLine($"{hit.Source.Author}: {hit.Source.Text}");
}

// Gelişmiş arama
var advancedSearch = await client.SearchAsync<Document>(s => s
    .Index("test-index")
    .Query(q => q
        .Bool(b => b
            .Must(m => m
                .Match(mt => mt
                    .Field(f => f.Text)
                    .Query("elasticsearch")
                )
            )
            .Filter(f => f
                .DateRange(dr => dr
                    .Field(fd => fd.Timestamp)
                    .GreaterThanOrEquals(DateTime.UtcNow.AddDays(-7))
                )
            )
        )
    )
    .Sort(so => so
        .Descending(d => d.Timestamp)
    )
    .From(0)
    .Size(10)
);

// Aggregation örneği
var aggregationResponse = await client.SearchAsync<Document>(s => s
    .Index("test-index")
    .Size(0)
    .Aggregations(a => a
        .Terms("authors", t => t
            .Field(f => f.Author.Suffix("keyword"))
            .Size(10)
        )
    )
);

var authorsAgg = aggregationResponse.Aggregations.Terms("authors");
foreach (var bucket in authorsAgg.Buckets)
{
    Console.WriteLine($"{bucket.Key}: {bucket.DocCount}");
}

// Döküman güncelle
var updateResponse = await client.UpdateAsync<Document, object>("1", u => u
    .Index("test-index")
    .Doc(new { Text = "Updated text from .NET" })
);

// Döküman sil
var deleteResponse = await client.DeleteAsync<Document>("1", d => d
    .Index("test-index")
);

// Index sil
var deleteIndexResponse = await client.Indices.DeleteAsync("test-index");
```

**NuGet Paketi:**
```powershell
dotnet add package NEST
```

**ASP.NET Core ile Dependency Injection:**
```csharp
// Program.cs
using Nest;

builder.Services.AddSingleton<IElasticClient>(sp =>
{
    var settings = new ConnectionSettings(new Uri("http://localhost:9200"))
        .BasicAuthentication("elastic", "your_password")
        .DefaultIndex("myapp");

    return new ElasticClient(settings);
});

// Service sınıfı
public class SearchService
{
    private readonly IElasticClient _elasticClient;

    public SearchService(IElasticClient elasticClient)
    {
        _elasticClient = elasticClient;
    }

    public async Task<List<Product>> SearchProductsAsync(string searchTerm)
    {
        var searchResponse = await _elasticClient.SearchAsync<Product>(s => s
            .Index("products")
            .Query(q => q
                .MultiMatch(mm => mm
                    .Fields(f => f
                        .Field(p => p.Name, boost: 2.0)
                        .Field(p => p.Description)
                        .Field(p => p.Category)
                    )
                    .Query(searchTerm)
                    .Fuzziness(Fuzziness.Auto)
                )
            )
            .Highlight(h => h
                .Fields(f => f
                    .Field(p => p.Name)
                    .Field(p => p.Description)
                )
            )
        );

        return searchResponse.Documents.ToList();
    }

    public async Task IndexProductAsync(Product product)
    {
        await _elasticClient.IndexAsync(product, idx => idx
            .Index("products")
            .Id(product.Id.ToString())
        );
    }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public string Category { get; set; }
    public decimal Price { get; set; }
}
```

## 📊 Kibana Dev Tools Örnekleri

Kibana Dev Tools Console'da çalıştırabileceğiniz örnek sorgular:

### Temel İşlemler

```json
# Cluster health
GET /_cluster/health

# Node bilgileri
GET /_cat/nodes?v

# Index listesi
GET /_cat/indices?v

# Index oluştur
PUT /my-index

# Mapping tanımla
PUT /my-index/_mapping
{
  "properties": {
    "name": { "type": "text" },
    "age": { "type": "integer" },
    "email": { "type": "keyword" },
    "created_at": { "type": "date" }
  }
}

# Döküman ekle
POST /my-index/_doc/1
{
  "name": "John Doe",
  "age": 30,
  "email": "john@example.com",
  "created_at": "2026-02-21T10:00:00"
}

# Döküman getir
GET /my-index/_doc/1

# Döküman güncelle
POST /my-index/_update/1
{
  "doc": {
    "age": 31
  }
}

# Döküman sil
DELETE /my-index/_doc/1
```

### Arama Sorguları

```json
# Tüm dökümanları getir
GET /my-index/_search

# Match query
GET /my-index/_search
{
  "query": {
    "match": {
      "name": "John"
    }
  }
}

# Term query
GET /my-index/_search
{
  "query": {
    "term": {
      "email": "john@example.com"
    }
  }
}

# Range query
GET /my-index/_search
{
  "query": {
    "range": {
      "age": {
        "gte": 25,
        "lte": 35
      }
    }
  }
}

# Bool query (birden fazla koşul)
GET /my-index/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "John" } }
      ],
      "filter": [
        { "range": { "age": { "gte": 18 } } }
      ]
    }
  }
}

# Aggregation (gruplama)
GET /my-index/_search
{
  "size": 0,
  "aggs": {
    "avg_age": {
      "avg": { "field": "age" }
    },
    "age_ranges": {
      "range": {
        "field": "age",
        "ranges": [
          { "to": 20 },
          { "from": 20, "to": 30 },
          { "from": 30 }
        ]
      }
    }
  }
}
```

### Bulk Operations

```json
# Bulk insert
POST /_bulk
{ "index": { "_index": "my-index" } }
{ "name": "Alice", "age": 25, "email": "alice@example.com" }
{ "index": { "_index": "my-index" } }
{ "name": "Bob", "age": 35, "email": "bob@example.com" }
{ "index": { "_index": "my-index" } }
{ "name": "Charlie", "age": 28, "email": "charlie@example.com" }
```

##  Veri Kalıcılığı (Persistence)

Her ortam için ayrı named volumes kullanılır:

**Development:**
- `elasticsearch_dev_data` - Elasticsearch verileri ve indeksler
- `kibana_dev_data` - Kibana yapılandırması ve saved objects

**Test:**
- `elasticsearch_test_data`
- `kibana_test_data`

**Production:**
- `elasticsearch_prod_data`
- `kibana_prod_data`

### Volume Yönetimi

```powershell
# Tüm Elasticsearch volumes listele
docker volume ls | Select-String "elasticsearch"

# Belirli bir volume'u incele
docker volume inspect elasticsearch_dev_data

# Volume'u manuel sil (container durdurulmuş olmalı)
docker volume rm elasticsearch_dev_data
```

## 🛡️ Güvenlik En İyi Pratikleri

### 1. Şifre Güvenliği
```powershell
# ❌ YANLIŞ - Zayıf şifre
ELASTIC_PASSWORD=changeme

# ✅ DOĞRU - Güçlü şifre
ELASTIC_PASSWORD=Kx9&mP2$vL8@qR5#wN3!
```

### 2. Environment Ayrımı
- Development ve Test için basit şifreler kullanılabilir
- Production için **mutlaka** güçlü, benzersiz şifreler kullanın
- Production şifrelerini asla development ile aynı yapmayın

### 3. Network Güvenliği
- Production'da SSL/TLS kullanın
- Firewall kuralları ile erişimi kısıtlayın
- API key veya token tabanlı kimlik doğrulama kullanın
- Hassas verileri şifreleyin

### 4. Index Güvenliği
- Role-based access control (RBAC) kullanın
- Her uygulama için ayrı kullanıcı oluşturun
- Index-level security ayarlayın
- Audit logging etkinleştirin

## 📊 İzleme ve Bakım

### Container Durumunu Kontrol Etme

**Script ile:**
```powershell
.\manage.ps1 status dev elasticsearch
```

**Manuel:**
```powershell
# Tüm containerlar
docker ps

# Elasticsearch containerları
docker ps | Select-String "elasticsearch"

# Belirli bir ortam
Set-Location environments\dev
docker-compose ps
```

### Cluster Health

```powershell
# Development
$password = "your_password"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("elastic:{0}" -f $password)))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

Invoke-RestMethod -Uri "http://localhost:9200/_cluster/health?pretty" -Headers $headers

# Detaylı bilgi
Invoke-RestMethod -Uri "http://localhost:9200/_cat/health?v" -Headers $headers
Invoke-RestMethod -Uri "http://localhost:9200/_cat/nodes?v" -Headers $headers
Invoke-RestMethod -Uri "http://localhost:9200/_cat/indices?v" -Headers $headers
```

### Disk Kullanımı
```powershell
# Volume'leri listele
docker volume ls | Select-String "elasticsearch"

# Volume boyutunu kontrol et
docker system df -v

# Index boyutları
Invoke-RestMethod -Uri "http://localhost:9200/_cat/indices?v&h=index,store.size" -Headers $headers
```

### Logları İnceleme

**Script ile:**
```powershell
# Canlı log izleme
.\manage.ps1 logs dev elasticsearch
```

**Manuel:**
```powershell
# Development ortamı
Set-Location environments\dev
docker-compose logs -f

# Son 100 satır
docker-compose logs --tail=100

# Container logları
docker logs elasticsearch_dev
docker logs kibana_dev
```

### Snapshot (Backup) Alma

```json
# Snapshot repository oluştur (Kibana Dev Tools)
PUT /_snapshot/my_backup
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/backup"
  }
}

# Snapshot al
PUT /_snapshot/my_backup/snapshot_1
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": false
}

# Snapshot listesi
GET /_snapshot/my_backup/_all

# Snapshot'tan restore et
POST /_snapshot/my_backup/snapshot_1/_restore
```

## 🐛 Sorun Giderme

### Port Zaten Kullanılıyor

```powershell
# Port kontrolü
netstat -ano | findstr :9200
```

**Çözüm:** İlgili ortamın `.env` dosyasında portu değiştirin.

### Elasticsearch Başlamıyor

```powershell
# Logları kontrol et
docker logs elasticsearch_dev

# Yaygın sorunlar:
# 1. Memory yetersiz - docker-compose.yml'deki ES_JAVA_OPTS değerini düşürün
# 2. Disk alanı yetersiz - docker system df ile kontrol edin
```

### Kibana Bağlanamıyor

```powershell
# Elasticsearch hazır mı kontrol et
Invoke-RestMethod -Uri "http://localhost:9200" -Headers $headers

# Kibana health check
docker exec kibana_dev powershell -Command "Invoke-RestMethod -Uri 'http://localhost:5601/api/status'"
```

### Index Oluşturulamıyor

```powershell
# Disk alanını kontrol et
Invoke-RestMethod -Uri "http://localhost:9200/_cat/allocation?v" -Headers $headers

# Shard durumu
Invoke-RestMethod -Uri "http://localhost:9200/_cat/shards?v" -Headers $headers
```

## 💡 İpuçları ve Best Practices

1. **Index lifecycle management** kullanarak eski verileri temizleyin
2. **Replica sayısını** single node'da 0 yapın
3. **Mapping'leri** önceden tanımlayın
4. **Bulk API** kullanarak toplu insert yapın
5. **Filter context** kullanarak query performance'ı artırın
6. **Aggregation'ları** optimize edin
7. **Index template'leri** kullanın
8. **Düzenli snapshot** alın
9. **Monitoring** için Kibana Stack Monitoring'i aktive edin
10. **Log aggregation** için Filebeat veya Logstash kullanın

## 🎯 Örnek Senaryolar

### Senaryo 1: Log Analizi

```json
# Log index oluştur
PUT /app-logs-2026.02
{
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "message": { "type": "text" },
      "service": { "type": "keyword" },
      "user_id": { "type": "keyword" }
    }
  }
}

# Log entry ekle
POST /app-logs-2026.02/_doc
{
  "timestamp": "2026-02-21T10:30:00",
  "level": "ERROR",
  "message": "Database connection failed",
  "service": "api",
  "user_id": "user123"
}

# Error logları ara
GET /app-logs-2026.02/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "level": "ERROR" } }
      ],
      "filter": [
        { "range": { "timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "sort": [
    { "timestamp": "desc" }
  ]
}
```

### Senaryo 2: E-commerce Arama

```json
# Product index
PUT /products
{
  "mappings": {
    "properties": {
      "name": { "type": "text" },
      "description": { "type": "text" },
      "category": { "type": "keyword" },
      "price": { "type": "float" },
      "stock": { "type": "integer" },
      "tags": { "type": "keyword" }
    }
  }
}

# Ürün ara (fuzzy match)
GET /products/_search
{
  "query": {
    "multi_match": {
      "query": "laptop gaming",
      "fields": ["name^2", "description", "tags"],
      "fuzziness": "AUTO"
    }
  }
}

# Fiyat aralığı ve kategori filtresi
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "laptop" } }
      ],
      "filter": [
        { "term": { "category": "electronics" } },
        { "range": { "price": { "gte": 500, "lte": 2000 } } },
        { "range": { "stock": { "gt": 0 } } }
      ]
    }
  },
  "sort": [
    { "price": "asc" }
  ]
}
```

## 📚 Ek Kaynaklar

- [Elasticsearch Resmi Dokümantasyon](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Dokümantasyon](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Elasticsearch Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Elasticsearch Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/best-practices.html)

## ❓ Sık Sorulan Sorular

**S: Neden single node mode?**
A: Development ve test için basitlik. Production'da cluster kurulumu önerilir.

**S: Memory ayarları neden bu kadar düşük?**
A: Local development için optimize edilmiş. Production'da artırılmalı (minimum 2GB).

**S: X-Pack Security ücretsiz mi?**
A: Temel security özellikleri ücretsiz, advanced özellikler lisans gerektirir.

**S: Index'ler container restart'ta silinir mi?**
A: Hayır, volume'de saklandığı için korunur.

**S: Cluster kurmak için ne yapmalıyım?**
A: Multi-node docker-compose yapılandırması veya Kubernetes kullanın.

---

**Hazırlayan**: Docker Elasticsearch Multi-Environment Setup  
**Son Güncelleme**: 2026-02-21  
**Versiyon**: 1.0.0

Herhangi bir sorunuz veya sorununuz olursa, documentation'ı kontrol edin! 🚀
