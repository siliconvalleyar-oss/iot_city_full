#!/bin/bash

# fix.sh - Limpia archivos de caché de Python y configura .gitignore

echo "🔧 Limpiando archivos de caché de Python..."

# 1. Eliminar todos los directorios __pycache__
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

# 2. Eliminar archivos .pyc y .pyo
find . -type f \( -name "*.pyc" -o -name "*.pyo" -o -name "*.pyd" \) -delete 2>/dev/null

# 3. Crear backup del .gitignore actual si existe
if [ -f .gitignore ]; then
    cp .gitignore .gitignore.backup
    echo "📋 Backup creado: .gitignore.backup"
fi

# 4. Escribir nuevo .gitignore
cat > .gitignore << 'EOF'
# Python cache
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Entornos virtuales
venv/
scripts/venv/
.env
.venv
env/
ENV/

# Directorios de compilación
stuff/
obj/
bin/
build/
examples/obj/
examples/bin/

# Logs
logs/
*.log

# Archivos objeto y ejecutables
*.o
*.exe
*.out
*.a
*.so
.DS_Store

# Archivos temporales
*.swp
*.swo
*~
*.d

# IDE
.vscode/
.idea/
*.user

# Archivos específicos
token.md
fix.sh
prompt.md

# Directorios de salida
analytics/__pycache__/
backend/__pycache__/
dashboard/__pycache__/
energy/__pycache__/
mqtt/__pycache__/
simulator/__pycache__/
src/*.o

# Assets (excepto los íconos)
assets/*
!assets/icons/
EOF

echo "✅ .gitignore actualizado correctamente"

# 5. Limpiar el índice de git si es necesario
if [ -d .git ]; then
    echo "🗑️  Limpiando archivos del índice git..."
    git rm -r --cached $(git ls-files | grep -E "(__pycache__|\.pyc$|\.pyo$)") 2>/dev/null
    git rm -r --cached venv/ scripts/venv/ 2>/dev/null
    echo "✅ Archivos removidos del índice git"
fi

echo ""
echo "✨ Proceso completado!"
echo "📝 Si estás satisfecho, ejecuta: git add .gitignore && git commit -m 'Actualizar .gitignore'"
