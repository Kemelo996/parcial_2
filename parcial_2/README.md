# Parcial Flutter — Accidentes Tuluá + CRUD Establecimientos

## Descripción

Aplicación Flutter con dos módulos integrados:

1. **Estadísticas de Accidentes de Tránsito en Tuluá** — consume el dataset público de Datos Abiertos Colombia, procesa los registros en un Isolate y visualiza 4 estadísticas con `fl_chart`.
2. **CRUD de Establecimientos** — consume la API REST del sistema de parqueadero para gestionar establecimientos con soporte de carga de logo.

---

## APIs Consumidas

### API 1 — Accidentes de Tránsito Tuluá

- **Fuente:** Datos Abiertos Colombia
- **Base URL:** `https://www.datos.gov.co/resource/ezt8-5wyj.json`
- **Autenticación:** Ninguna requerida
- **Endpoint usado:** `GET ...?$limit=100000`

**Campos relevantes del JSON:**
| Campo | Descripción |
|---|---|
| `clase_de_accidente` | Tipo: Choque, Atropello, Volcamiento, etc. |
| `gravedad_del_accidente` | Con muertos / Con heridos / Solo daños |
| `barrio_hecho` | Barrio donde ocurrió el accidente |
| `dia` | Día de la semana |
| `hora` | Hora del accidente |
| `area` | Área urbana o rural |
| `clase_de_vehiculo` | Tipo de vehículo involucrado |

**Ejemplo de respuesta JSON:**
```json
[
  {
    "clase_de_accidente": "Choque",
    "gravedad_del_accidente": "Con heridos",
    "barrio_hecho": "Centro",
    "dia": "Viernes",
    "hora": "18:30:00",
    "area": "Urbana",
    "clase_de_vehiculo": "Automóvil"
  }
]
```

### API 2 — Establecimientos (Parqueadero)

- **Fuente:** VisionTIC
- **Base URL:** `https://parking.visiontic.com.co/api`
- **Documentación:** [Swagger](https://parking.visiontic.com.co/api/documentation)

**Endpoints usados:**
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/establecimientos` | Listar todos |
| GET | `/establecimientos/{id}` | Ver uno |
| POST | `/establecimientos` | Crear (multipart/form-data) |
| POST | `/establecimiento-update/{id}` | Editar con `_method=PUT` |
| DELETE | `/establecimientos/{id}` | Eliminar |

> La API usa **method spoofing de Laravel**: para editar, se hace POST con el campo `_method=PUT` en el form-data.

**Ejemplo de respuesta JSON:**
```json
{
  "data": [
    {
      "id": 1,
      "nombre": "Parqueadero Central",
      "nit": "900.123.456-7",
      "direccion": "Cra 5 # 10-20",
      "telefono": "3001234567",
      "logo": "https://parking.visiontic.com.co/storage/logos/logo.png"
    }
  ]
}
```

---

## Future/async/await vs Isolate

### ¿Cuándo usar `Future`/`async`/`await`?
Para operaciones de I/O (peticiones HTTP, lectura de archivos, base de datos) que están bloqueadas esperando una respuesta externa. Dart las maneja de forma asíncrona sin bloquear el hilo principal y sin necesitar un hilo adicional real.

### ¿Cuándo usar Isolate?
Para procesamiento **intensivo de CPU** que sí bloquearía el hilo principal (UI thread). Los Isolates son procesos paralelos con su propia memoria.

### ¿Por qué se usó Isolate aquí?
El endpoint `?$limit=100000` descarga potencialmente decenas de miles de registros JSON. Una vez descargados, calcular las 4 estadísticas (iterar toda la lista, agrupar, ordenar) es una operación de CPU que **bloquearía el hilo de UI** causando jank/freeze si se hiciera con `async/await`. Por eso se pasa la lista completa a `Isolate.run()` para procesarla en segundo plano mientras la UI permanece fluida.

---

## Arquitectura y Estructura del Proyecto

```
lib/
├── main.dart                         # Entry point, configura app y dotenv
├── router/
│   └── app_router.dart               # GoRouter con todas las rutas nombradas
├── models/
│   ├── accidente_model.dart          # Modelo Accidente con fromJson
│   └── establecimiento_model.dart    # Modelo Establecimiento con fromJson/toJson
├── services/
│   ├── accidentes_service.dart       # Dio: GET accidentes con $limit
│   └── establecimientos_service.dart # Dio: CRUD completo con multipart
├── isolates/
│   └── accidentes_isolate.dart       # Función pura que corre en Isolate.run()
└── views/
    ├── dashboard/
    │   └── dashboard_screen.dart     # Pantalla principal con cards de acceso
    ├── accidentes/
    │   └── accidentes_screen.dart    # 4 gráficas con fl_chart
    └── establecimientos/
        ├── establecimientos_screen.dart          # Lista con ListView.builder
        ├── establecimiento_detalle_screen.dart   # Ver + botones editar/eliminar
        └── establecimiento_form_screen.dart      # Formulario crear/editar
```

---

## Rutas con go_router

| Nombre | Path | Parámetros | Descripción |
|---|---|---|---|
| `dashboard` | `/` | — | Pantalla principal |
| `accidentes` | `/accidentes` | — | Estadísticas con 4 gráficas |
| `establecimientos` | `/establecimientos` | — | Lista de establecimientos |
| `establecimiento-crear` | `/establecimientos/nuevo` | — | Formulario de creación |
| `establecimiento-detalle` | `/establecimientos/:id` | `id` (path param) | Vista detalle |
| `establecimiento-editar` | `/establecimientos/:id/editar` | `id` (path param), `extra` (Map con datos) | Formulario edición |

**Navegación con parámetros:**
```dart
// Navegar a detalle
context.pushNamed('establecimiento-detalle', pathParameters: {'id': '5'});

// Navegar a editar pasando datos en extra
context.pushNamed(
  'establecimiento-editar',
  pathParameters: {'id': '5'},
  extra: establecimiento.toJson(),
);
```

---

## Paquetes Utilizados

| Paquete | Uso |
|---|---|
| `dio` | HTTP client para ambas APIs |
| `go_router` | Navegación declarativa con rutas nombradas |
| `flutter_dotenv` | URLs base en archivo `.env` |
| `fl_chart` | PieChart y BarChart para las 4 estadísticas |
| `skeletonizer` | Efecto skeleton mientras carga |
| `image_picker` | Selección de logo desde galería o cámara |
| `dart:isolate` | `Isolate.run()` para procesamiento en segundo plano |

---

## Variables de Entorno (.env)

```
ACCIDENTES_BASE_URL=https://www.datos.gov.co/resource/ezt8-5wyj.json
PARKING_BASE_URL=https://parking.visiontic.com.co/api
```

---

## Isolate — Mensajes en Consola

Al ejecutar la pantalla de estadísticas se verán en consola:

```
[Isolate] Iniciado — 15420 registros recibidos
[Isolate] Completado en 312 ms
```

---
