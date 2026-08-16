# Asistente JRMNS

Aplicación personal de productividad para Android. Funciona 100% offline.

## Características
- Tareas diarias con check-in y progreso
- Gestión laboral y familiar
- Presupuesto mensual (ingresos/gastos)
- Bóveda segura con cifrado AES y PIN

## Tecnologías
- Flutter + Dart
- SQLite (sqflite)
- Provider (estado)
- AES Encryption

## Cómo ejecutar
1. Instalar Flutter: https://docs.flutter.dev/get-started/install
2. Clonar/abrir este proyecto en VS Code
3. Ejecutar: `flutter pub get`
4. Conectar teléfono o emulador
5. Ejecutar: `flutter run`

## Generar APK
```bash
flutter build apk --release
```
El APK aparece en: `build/app/outputs/flutter-apk/app-release.apk`

## Cambiar icono
Reemplazar archivos en `android/app/src/main/res/mipmap-*/`

## Package
`com.jrmns.asistente`
