# Contributing to Local Analytics Lab

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

```bash
# Clone the repo
git clone https://github.com/yourusername/local-analytics-lab.git
cd local-analytics-lab

# Start the stack
./install.sh
```

## Testing Your Changes

Before submitting a PR, ensure:

1. **All services start successfully**:
   ```bash
   just up
   sleep 60
   just ps  # All services should be healthy
   ```

2. **Integration tests pass**:
   ```bash
   # Test Spark → MinIO
   docker-compose exec spark-master /opt/spark/bin/spark-submit /opt/spark-apps/test_spark_minio.py
   
   # Test Trino → Hive → MinIO
   docker-compose exec trino trino --execute "SELECT * FROM hive.analytics.employees LIMIT 5"
   ```

3. **Clean slate works**:
   ```bash
   just clean
   just up
   # Verify everything auto-configures
   ```

## Pull Request Guidelines

- Keep changes focused and atomic
- Update documentation if needed
- Add comments for complex logic
- Test on a fresh installation
- Include screenshots for UI changes

## Code Style

- Use meaningful variable names
- Follow existing patterns
- Add comments for non-obvious code
- Keep Dockerfile layers minimal

## Reporting Issues

When reporting issues, include:

- Operating system and version
- Docker Desktop version
- Complete error messages
- Steps to reproduce
- Service logs: `just logs [service-name]`

## Feature Requests

For new features:

1. Check if it already exists or is planned
2. Open an issue describing the feature
3. Discuss implementation approach
4. Submit PR after approval

## Areas for Contribution

- Additional sample DAGs
- More test datasets
- Documentation improvements
- Performance optimizations
- New service integrations
- Bug fixes

## Questions?

Open an issue with the `question` label or reach out to the maintainers.

---

**Thank you for helping make Local Analytics Lab better!**
