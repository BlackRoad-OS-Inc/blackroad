/**
 * Language Detection Engine
 * 
 * Automatically detects project language and framework from repository structure.
 * Supports: Node.js, Python, Java, C#, Go, Rust, PHP, Ruby
 */

const fs = require('fs');
const path = require('path');

class LanguageDetector {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.files = this.scanDirectory(projectPath);
  }

  scanDirectory(dir) {
    try {
      return fs.readdirSync(dir);
    } catch (err) {
      console.error(`Error scanning directory: ${err.message}`);
      return [];
    }
  }

  detect() {
    // Check for config files in priority order
    const detectors = [
      { file: 'package.json', language: 'nodejs', framework: this.detectNodeFramework() },
      { file: 'requirements.txt', language: 'python', framework: this.detectPythonFramework() },
      { file: 'pyproject.toml', language: 'python', framework: 'poetry' },
      { file: 'pom.xml', language: 'java', framework: 'maven' },
      { file: 'build.gradle', language: 'java', framework: 'gradle' },
      { file: 'build.gradle.kts', language: 'java', framework: 'gradle-kotlin' },
      { file: '.csproj', language: 'csharp', framework: 'dotnet', pattern: /\.csproj$/ },
      { file: '.sln', language: 'csharp', framework: 'dotnet', pattern: /\.sln$/ },
      { file: 'go.mod', language: 'go', framework: 'go-modules' },
      { file: 'Cargo.toml', language: 'rust', framework: 'cargo' },
      { file: 'composer.json', language: 'php', framework: this.detectPHPFramework() },
      { file: 'Gemfile', language: 'ruby', framework: this.detectRubyFramework() },
    ];

    for (const detector of detectors) {
      if (detector.pattern) {
        // Pattern-based detection (e.g., .csproj)
        const match = this.files.find(f => detector.pattern.test(f));
        if (match) {
          return {
            language: detector.language,
            framework: detector.framework,
            configFile: match,
            dockerfile: `Dockerfile.${detector.language}`,
          };
        }
      } else if (this.files.includes(detector.file)) {
        return {
          language: detector.language,
          framework: detector.framework,
          configFile: detector.file,
          dockerfile: `Dockerfile.${detector.language}`,
        };
      }
    }

    // Fallback: check for common source file extensions
    return this.detectByExtension();
  }

  detectNodeFramework() {
    try {
      const pkgPath = path.join(this.projectPath, 'package.json');
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      
      if (pkg.dependencies) {
        if (pkg.dependencies.next) return 'next';
        if (pkg.dependencies.express) return 'express';
        if (pkg.dependencies.fastify) return 'fastify';
        if (pkg.dependencies['@nestjs/core']) return 'nestjs';
        if (pkg.dependencies.koa) return 'koa';
        if (pkg.dependencies.nuxt) return 'nuxt';
      }
      
      return 'node';
    } catch {
      return 'node';
    }
  }

  detectPythonFramework() {
    try {
      const reqPath = path.join(this.projectPath, 'requirements.txt');
      const requirements = fs.readFileSync(reqPath, 'utf8');
      
      if (requirements.includes('django')) return 'django';
      if (requirements.includes('flask')) return 'flask';
      if (requirements.includes('fastapi')) return 'fastapi';
      if (requirements.includes('tornado')) return 'tornado';
      
      return 'python';
    } catch {
      return 'python';
    }
  }

  detectPHPFramework() {
    try {
      const composerPath = path.join(this.projectPath, 'composer.json');
      const composer = JSON.parse(fs.readFileSync(composerPath, 'utf8'));
      
      if (composer.require) {
        if (composer.require['laravel/framework']) return 'laravel';
        if (composer.require['symfony/symfony']) return 'symfony';
      }
      
      return 'php';
    } catch {
      return 'php';
    }
  }

  detectRubyFramework() {
    try {
      const gemfilePath = path.join(this.projectPath, 'Gemfile');
      const gemfile = fs.readFileSync(gemfilePath, 'utf8');
      
      if (gemfile.includes('rails')) return 'rails';
      if (gemfile.includes('sinatra')) return 'sinatra';
      
      return 'ruby';
    } catch {
      return 'ruby';
    }
  }

  detectByExtension() {
    const extensionMap = {
      '.js': 'nodejs',
      '.ts': 'nodejs',
      '.py': 'python',
      '.java': 'java',
      '.cs': 'csharp',
      '.go': 'go',
      '.rs': 'rust',
      '.php': 'php',
      '.rb': 'ruby',
    };

    for (const file of this.files) {
      const ext = path.extname(file);
      if (extensionMap[ext]) {
        return {
          language: extensionMap[ext],
          framework: extensionMap[ext],
          configFile: null,
          dockerfile: `Dockerfile.${extensionMap[ext]}`,
        };
      }
    }

    // Default fallback
    return {
      language: 'unknown',
      framework: 'unknown',
      configFile: null,
      dockerfile: 'Dockerfile',
    };
  }

  getPort() {
    const { language, framework } = this.detect();
    
    const defaultPorts = {
      nodejs: 3000,
      python: 5000,
      java: 8080,
      csharp: 5000,
      go: 8080,
      rust: 8080,
      php: 8000,
      ruby: 3000,
      
      // Framework-specific
      next: 3000,
      django: 8000,
      flask: 5000,
      fastapi: 8000,
      rails: 3000,
      laravel: 8000,
    };

    return defaultPorts[framework] || defaultPorts[language] || 8080;
  }
}

module.exports = LanguageDetector;

// CLI usage
if (require.main === module) {
  const projectPath = process.argv[2] || process.cwd();
  const detector = new LanguageDetector(projectPath);
  const result = detector.detect();
  
  console.log(JSON.stringify({
    ...result,
    defaultPort: detector.getPort(),
  }, null, 2));
}
