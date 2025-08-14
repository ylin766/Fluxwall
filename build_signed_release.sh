#!/bin/bash

# Fluxwall 签名版本打包脚本
# 用于构建、签名和公证 macOS 应用程序

set -e

# 配置变量
APP_NAME="Fluxwall"
PROJECT_NAME="Fluxwall"
SCHEME_NAME="Fluxwall"
CONFIGURATION="Release"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DMG_NAME="$APP_NAME-Installer"
VERSION=$(date +"%Y.%m.%d")

# 签名配置 (需要根据实际情况修改)
DEVELOPER_ID_APPLICATION=""  # 例如: "Developer ID Application: Your Name (TEAM_ID)"
DEVELOPER_ID_INSTALLER=""    # 例如: "Developer ID Installer: Your Name (TEAM_ID)"
APPLE_ID=""                  # 你的 Apple ID
APP_SPECIFIC_PASSWORD=""     # App-specific password
TEAM_ID=""                   # 你的 Team ID

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查签名配置
check_signing_config() {
    log_info "检查签名配置..."
    
    if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
        log_warning "未配置 DEVELOPER_ID_APPLICATION，将跳过代码签名"
        return 1
    fi
    
    if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
        log_warning "未配置 Apple ID 或 App-specific password，将跳过公证"
        return 1
    fi
    
    # 检查证书是否存在
    if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID_APPLICATION"; then
        log_error "找不到签名证书: $DEVELOPER_ID_APPLICATION"
        return 1
    fi
    
    log_success "签名配置检查完成"
    return 0
}

# 构建并签名应用
build_signed_app() {
    log_info "构建签名版本..."
    
    # 清理项目
    xcodebuild clean \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION"
    
    # 创建 Archive (带签名)
    xcodebuild archive \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
        CODE_SIGNING_REQUIRED=YES \
        CODE_SIGNING_ALLOWED=YES \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime"
    
    log_success "签名版本构建完成"
}

# 导出签名应用
export_signed_app() {
    log_info "导出签名应用..."
    
    # 创建导出配置文件
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>signingCertificate</key>
    <string>$DEVELOPER_ID_APPLICATION</string>
</dict>
</plist>
EOF
    
    # 导出应用
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
    
    log_success "签名应用导出完成"
}

# 验证签名
verify_signature() {
    log_info "验证应用签名..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "找不到应用: $APP_PATH"
        return 1
    fi
    
    # 验证签名
    codesign --verify --verbose=2 "$APP_PATH"
    
    # 检查签名详情
    codesign -dv --verbose=4 "$APP_PATH"
    
    # 验证 Gatekeeper 兼容性
    spctl --assess --verbose=2 "$APP_PATH"
    
    log_success "签名验证完成"
}

# 公证应用
notarize_app() {
    log_info "开始公证应用..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    ZIP_PATH="$BUILD_DIR/$APP_NAME-notarization.zip"
    
    # 创建用于公证的 ZIP
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    
    # 提交公证
    log_info "提交公证请求..."
    NOTARIZATION_RESULT=$(xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait)
    
    echo "$NOTARIZATION_RESULT"
    
    # 检查公证结果
    if echo "$NOTARIZATION_RESULT" | grep -q "status: Accepted"; then
        log_success "公证成功"
        
        # 装订公证票据
        log_info "装订公证票据..."
        xcrun stapler staple "$APP_PATH"
        
        # 验证装订
        xcrun stapler validate "$APP_PATH"
        
        log_success "公证票据装订完成"
    else
        log_error "公证失败"
        return 1
    fi
    
    # 清理临时文件
    rm -f "$ZIP_PATH"
}

# 创建签名的 DMG
create_signed_dmg() {
    log_info "创建签名 DMG..."
    
    DMG_PATH="$BUILD_DIR/$DMG_NAME-Signed.dmg"
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    
    # 创建临时 DMG 目录
    DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
    mkdir -p "$DMG_TEMP_DIR"
    
    # 复制应用到临时目录
    cp -R "$APP_PATH" "$DMG_TEMP_DIR/"
    
    # 创建 Applications 链接
    ln -s /Applications "$DMG_TEMP_DIR/Applications"
    
    # 创建 DMG
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "$APP_NAME" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --icon "$APP_NAME.app" 200 190 \
            --hide-extension "$APP_NAME.app" \
            --app-drop-link 600 185 \
            "$DMG_PATH" \
            "$DMG_TEMP_DIR"
    else
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$DMG_TEMP_DIR" \
            -ov -format UDZO \
            "$DMG_PATH"
    fi
    
    # 签名 DMG
    if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
        log_info "签名 DMG..."
        codesign --sign "$DEVELOPER_ID_APPLICATION" \
            --timestamp \
            --options runtime \
            "$DMG_PATH"
        
        log_success "DMG 签名完成"
    fi
    
    # 清理临时目录
    rm -rf "$DMG_TEMP_DIR"
    
    log_success "签名 DMG 创建完成: $DMG_PATH"
}

# 创建安装包 (.pkg)
create_installer_pkg() {
    log_info "创建安装包..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    PKG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.pkg"
    
    # 创建安装包
    pkgbuild --root "$EXPORT_PATH" \
        --identifier "com.fluxwall.app" \
        --version "$VERSION" \
        --install-location "/Applications" \
        "$PKG_PATH"
    
    # 签名安装包
    if [ -n "$DEVELOPER_ID_INSTALLER" ]; then
        log_info "签名安装包..."
        productsign --sign "$DEVELOPER_ID_INSTALLER" \
            "$PKG_PATH" \
            "$BUILD_DIR/$APP_NAME-$VERSION-Signed.pkg"
        
        # 替换为签名版本
        mv "$BUILD_DIR/$APP_NAME-$VERSION-Signed.pkg" "$PKG_PATH"
        
        log_success "安装包签名完成"
    fi
    
    log_success "安装包创建完成: $PKG_PATH"
}

# 显示构建信息
show_build_info() {
    log_info "构建信息:"
    echo "  应用名称: $APP_NAME"
    echo "  版本: $VERSION"
    echo "  配置: $CONFIGURATION"
    echo "  构建目录: $BUILD_DIR"
    
    if [ -f "$BUILD_DIR/$DMG_NAME-Signed.dmg" ]; then
        DMG_SIZE=$(du -h "$BUILD_DIR/$DMG_NAME-Signed.dmg" | cut -f1)
        echo "  签名 DMG 大小: $DMG_SIZE"
    fi
    
    if [ -f "$BUILD_DIR/$APP_NAME-$VERSION.pkg" ]; then
        PKG_SIZE=$(du -h "$BUILD_DIR/$APP_NAME-$VERSION.pkg" | cut -f1)
        echo "  安装包大小: $PKG_SIZE"
    fi
}

# 主函数
main() {
    log_info "开始构建签名版本 $APP_NAME..."
    
    # 清理构建目录
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # 检查签名配置
    if check_signing_config; then
        build_signed_app
        export_signed_app
        verify_signature
        
        # 如果配置了公证信息，则进行公证
        if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
            notarize_app
        fi
        
        create_signed_dmg
        create_installer_pkg
        show_build_info
        
        log_success "签名版本构建完成！"
    else
        log_warning "签名配置不完整，将构建未签名版本"
        # 回退到未签名构建
        ./build_release.sh
    fi
}

# 处理命令行参数
case "${1:-}" in
    "")
        main
        ;;
    *)
        echo "用法: $0"
        echo "构建签名版本的 Fluxwall 应用"
        echo ""
        echo "在使用前，请配置以下变量："
        echo "  DEVELOPER_ID_APPLICATION - 开发者 ID 应用证书"
        echo "  DEVELOPER_ID_INSTALLER   - 开发者 ID 安装包证书"
        echo "  APPLE_ID                 - Apple ID"
        echo "  APP_SPECIFIC_PASSWORD    - App-specific password"
        echo "  TEAM_ID                  - Team ID"
        exit 1
        ;;
esac