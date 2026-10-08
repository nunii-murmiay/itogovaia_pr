# PocketBase для зоомагазина «Лапки и Хвостики»

## Запуск

```powershell
cd pocketbase
.\pocketbase.exe superuser upsert admin@zoomag.local admin123456
.\pocketbase.exe serve
```

Панель: http://127.0.0.1:8090/_/  
API: http://127.0.0.1:8090/api/

## Демо-данные

В другом окне (сервер уже запущен):

```powershell
node seed.mjs
```

Учётки приложения:

| Логин (username) | Пароль | Роль |
|---|---|---|
| reader | reader123 | Покупатель |
| librarian | librarian123 | Менеджер |
| admin | admin123 | Администратор |

Вход в Flutter идёт по **username** или email через `auth-with-password`.
