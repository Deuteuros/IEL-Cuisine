# Guide de Lancement - Cuisine (Flutter)

Ce guide contient les commandes pour compiler et lancer l'application **Cuisine (Lakozia)**.

## 1. Prérequis (Linux)
Lance ces commandes directement à la racine du projet :
```bash
sudo apt-get update
sudo apt-get install -y build-essential clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev lld-18 libstdc++-13-dev
```

### Dépannage : Erreur headers C++ (`type_traits` non trouvé)
Si Clang (utilisé par Flutter) ne trouve pas `type_traits` ou d'autres fichiers d'en-tête C++, c'est qu'il tente d'utiliser une version supérieure de GCC installée sur ton système (par exemple GCC 14) alors que son paquet de développement C++ n'est pas présent.

**Solution propre (recommandée) :**
Installe la bibliothèque standard de développement correspondant à cette version supérieure de GCC (sur Zorin OS 18 / Ubuntu 24.04, c'est généralement la version 14) :
```bash
sudo apt install libstdc++-14-dev
```

**Alternative (si tu n'as pas les droits sudo) :**
Tu peux forcer Clang à utiliser les en-têtes de GCC 13 à l'aide de ces variables d'environnement avant de compiler :
```bash
export C_INCLUDE_PATH=/usr/include/c++/13:/usr/include/x86_64-linux-gnu/c++/13:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/usr/include/c++/13:/usr/include/x86_64-linux-gnu/c++/13:$CPLUS_INCLUDE_PATH
```

## 2. Configurer le chemin Flutter
```bash
export PATH="$PATH:/home/deuteuros/flutter/3.38.6/bin"
```

## 3. Lancer l'application
```bash
flutter pub get
flutter run -d linux
```

### Version Web (Chrome)
```bash
flutter run -d chrome
```

### Version Android (nécessite un émulateur ou un téléphone branché)
```bash
flutter run -d android
```

## 4. Compiler pour Android (APK)
```bash
flutter build apk --release
```
L'APK se trouvera dans : `build/app/outputs/flutter-apk/app-release.apk`
