#!/bin/bash

# PostgreSQL Docker Environment Yönetim Scripti
# Kullanım: ./manage.sh [komut] [ortam]
# Örnek: ./manage.sh start dev
#        ./manage.sh start all
#        ./manage.sh stop test

set -e

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonksiyonlar
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${CYAN}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Kullanım bilgisi
show_usage() {
    echo "Kullanım: $0 [komut] [ortam]"
    echo ""
    echo "Komutlar:"
    echo "  start    - Ortamı başlat"
    echo "  stop     - Ortamı durdur"
    echo "  restart  - Ortamı yeniden başlat"
    echo "  logs     - Logları göster"
    echo "  status   - Durum göster"
    echo "  clean    - Ortamı temizle (veriler silinir!)"
    echo ""
    echo "Ortamlar:"
    echo "  dev      - Development"
    echo "  test     - Test"
    echo "  prod     - Production"
    echo "  all      - Tüm ortamlar"
    echo ""
    echo "Örnekler:"
    echo "  $0 start dev"
    echo "  $0 stop all"
    echo "  $0 logs test"
    exit 1
}

# Parametre kontrolü
if [ $# -ne 2 ]; then
    show_usage
fi

ACTION=$1
ENVIRONMENT=$2

# Ortam bilgileri
declare -A ENV_PATHS=(
    ["dev"]="environments/dev"
    ["test"]="environments/test"
    ["prod"]="environments/prod"
)

declare -A ENV_NAMES=(
    ["dev"]="Development"
    ["test"]="Test"
    ["prod"]="Production"
)

# Ortam başlat
start_environment() {
    local env=$1
    local env_name=${ENV_NAMES[$env]}
    local env_path=${ENV_PATHS[$env]}
    
    print_info "🚀 $env_name ortamı başlatılıyor..."
    
    if [ ! -f "$env_path/docker-compose.yml" ]; then
        print_error "❌ $env_path/docker-compose.yml dosyası bulunamadı!"
        exit 1
    fi
    
    cd "$env_path"
    docker-compose up -d
    cd - > /dev/null
    
    if [ $? -eq 0 ]; then
        print_success "✅ $env_name ortamı başarıyla başlatıldı!"
    else
        print_error "❌ $env_name ortamı başlatılırken hata oluştu!"
    fi
}

# Ortam durdur
stop_environment() {
    local env=$1
    local env_name=${ENV_NAMES[$env]}
    local env_path=${ENV_PATHS[$env]}
    
    print_info "🛑 $env_name ortamı durduruluyor..."
    
    cd "$env_path"
    docker-compose down
    cd - > /dev/null
    
    if [ $? -eq 0 ]; then
        print_success "✅ $env_name ortamı başarıyla durduruldu!"
    else
        print_error "❌ $env_name ortamı durdurulurken hata oluştu!"
    fi
}

# Ortam yeniden başlat
restart_environment() {
    local env=$1
    stop_environment "$env"
    sleep 2
    start_environment "$env"
}

# Logları göster
show_logs() {
    local env=$1
    local env_name=${ENV_NAMES[$env]}
    local env_path=${ENV_PATHS[$env]}
    
    print_info "📋 $env_name ortamı logları gösteriliyor..."
    
    cd "$env_path"
    docker-compose logs -f
    cd - > /dev/null
}

# Durum göster
show_status() {
    print_info "📊 Container durumları:"
    echo ""
    
    for env in dev test prod; do
        local env_name=${ENV_NAMES[$env]}
        local env_path=${ENV_PATHS[$env]}
        
        print_warning "=== $env_name ==="
        
        cd "$env_path"
        docker-compose ps
        cd - > /dev/null
        echo ""
    done
}

# Ortam temizle
clean_environment() {
    local env=$1
    local env_name=${ENV_NAMES[$env]}
    local env_path=${ENV_PATHS[$env]}
    
    print_warning "⚠️  $env_name ortamının TÜM VERİLERİ silinecek!"
    read -p "Devam etmek istiyor musunuz? (yes/no): " confirm
    
    if [ "$confirm" == "yes" ]; then
        print_info "🗑️  $env_name ortamı temizleniyor..."
        
        cd "$env_path"
        docker-compose down -v
        cd - > /dev/null
        
        print_success "✅ $env_name ortamı temizlendi!"
    else
        print_info "İşlem iptal edildi."
    fi
}

# Tüm ortamlar için işlem yap
process_all_environments() {
    local action=$1
    
    for env in dev test prod; do
        case $action in
            start)   start_environment "$env" ;;
            stop)    stop_environment "$env" ;;
            restart) restart_environment "$env" ;;
            clean)   clean_environment "$env" ;;
        esac
        echo ""
    done
    
    if [ "$action" == "status" ]; then
        show_status
    fi
}

# Ana başlık
print_info "═══════════════════════════════════════"
print_info "  PostgreSQL Docker Ortam Yöneticisi"
print_info "═══════════════════════════════════════"
echo ""

# Ana mantık
if [ "$ENVIRONMENT" == "all" ]; then
    case $ACTION in
        start|stop|restart|clean|status)
            process_all_environments "$ACTION"
            ;;
        *)
            print_error "Geçersiz komut: $ACTION"
            show_usage
            ;;
    esac
else
    # Ortam geçerliliğini kontrol et
    if [ -z "${ENV_PATHS[$ENVIRONMENT]}" ]; then
        print_error "Geçersiz ortam: $ENVIRONMENT"
        show_usage
    fi
    
    case $ACTION in
        start)   start_environment "$ENVIRONMENT" ;;
        stop)    stop_environment "$ENVIRONMENT" ;;
        restart) restart_environment "$ENVIRONMENT" ;;
        logs)    show_logs "$ENVIRONMENT" ;;
        status)  show_status ;;
        clean)   clean_environment "$ENVIRONMENT" ;;
        *)
            print_error "Geçersiz komut: $ACTION"
            show_usage
            ;;
    esac
fi

echo ""
print_info "═══════════════════════════════════════"
