// Theme.js - Quickshell 全组件统一主题 (Matugen Generated)
// 由 matugen 直接写入 ~/.config/quickshell/Commons/Theme.js
// 各组件通过 import "../Commons/Theme.js" as Theme 使用本文件

// Colors - Material You Dynamic
// 用 .default 而不是 .light/.dark：pullautumn 的 matugen-update.sh 按当前模式
// (matugen -m dark|light) 单次生成，.default 会跟随那次生成所用的模式
var background = "{{colors.surface.default.hex}}"
var surface = "{{colors.surface_container.default.hex}}"
var surfaceVariant = "{{colors.surface_variant.default.hex}}"
var primary = "{{colors.primary.default.hex}}"
var secondary = "{{colors.secondary.default.hex}}"
var tertiary = "{{colors.tertiary.default.hex}}"
var success = "{{colors.secondary.default.hex}}"
var warning = "{{colors.tertiary.default.hex}}"
var error = "{{colors.error.default.hex}}"
var textPrimary = "{{colors.on_surface.default.hex}}"
var textSecondary = "{{colors.on_surface_variant.default.hex}}"
var textMuted = "{{colors.outline.default.hex}}"
var outline = "{{colors.outline_variant.default.hex}}"

// Glassmorphism 3.0
// 取值跟着配色走，不用固定的黑/白：
// 深色模式 surface 是近黑 → 0.62 透明度接近上游的 alpha("#000000", 0.55)；
// 浅色模式 surface 是近白 → 接近上游浅色版的白色 0.72，文字仍然清晰。
var glassBg = alpha(background, 0.62)
var glassBorder = alpha(primary, 0.35)
var glassHighlight = alpha("#ffffff", 0.2)
var shadowColor = alpha("#000000", 0.35)
var ambientShadow = alpha(primary, 0.2)
var accentGlow = alpha(primary, 0.45)
var auroraGradient = [primary, secondary]

// Font sizes
var fontSizeXS = 10
var fontSizeS = 11
var fontSizeM = 12
var fontSizeL = 14
var fontSizeXL = 16
var fontSizeHuge = 28

// Spacing
var spacingXS = 4
var spacingS = 6
var spacingM = 10
var spacingL = 14
var spacingXL = 20

// Border radius
var radiusS = 6
var radiusM = 10
var radiusL = 14
var radiusXL = 20
var radiusPill = 100

// Icon sizes
var iconSizeS = 14
var iconSizeM = 18
var iconSizeL = 22

// Animation durations
var animFast = 120
var animNormal = 200
var animSlow = 300

// Helper function for alpha colors
function alpha(c, a) {
    // Parse hex color and return rgba string
    if (typeof c === "string" && c.startsWith("#")) {
        var hex = c.slice(1)
        var r, g, b
        if (hex.length === 3) {
            r = parseInt(hex[0] + hex[0], 16) / 255
            g = parseInt(hex[1] + hex[1], 16) / 255
            b = parseInt(hex[2] + hex[2], 16) / 255
        } else {
            r = parseInt(hex.slice(0, 2), 16) / 255
            g = parseInt(hex.slice(2, 4), 16) / 255
            b = parseInt(hex.slice(4, 6), 16) / 255
        }
        return Qt.rgba(r, g, b, a)
    }
    // If already a color object
    return Qt.rgba(c.r, c.g, c.b, a)
}
