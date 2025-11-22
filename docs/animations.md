### Mesh
Система анимаций доступна и на клиенте, и на сервере

Единственный доступный формат анимаций для работы **Meshup** - Анимации **GeckoLib**, создавать их можно в приложении **BlockBench** с помощью [плагина](https://www.blockbench.net/plugins/animation_utils) от **GeckoLib**

---
```lua
local animations = require "meshup:api/api".server.animations
```
- Импорт

### Методы Storage
```lua
animations.storage.load_animations(json: string)
```
- Загружает в память анимацию, в качестве имени анимации будет выбрано название первой анимации из json
- Ограниченная поддержка, не поддерживает несколько костей и несколько анимаций в одном файле

```lua
animations.storage.get_animation(name: string) -> table / nil
```
- Возвращает анимацию по имени
- Если анимация не загружена - **nil**