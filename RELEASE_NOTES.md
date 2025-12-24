# Local Analytics Lab
Version 1.0.0

## Release Notes

### Features
- Complete analytics stack with 6+ services
- One-command installation via `./install.sh`
- Pre-configured integrations between all services
- Sample dataset for immediate testing
- Persistent data across restarts
- Comprehensive documentation

### Services Included
- Apache Airflow 2.8.1
- Apache Spark 3.5.0
- MinIO (latest)
- Hive Metastore 4.0.0
- Trino 435
- Apache Superset (latest)
- PostgreSQL 15
- MySQL 8.0

### System Requirements
- macOS (tested on 15.3.1)
- Docker Desktop 4.x+
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space

### Installation
```bash
./install.sh
```

### Known Issues
- First startup takes 60-90 seconds
- Port 8080 must be available for Airflow
- Services may show as "starting" during initialization

### Documentation
- README.md - Quick start guide
- SETUP_JOURNEY.md - Detailed technical documentation
- CONTRIBUTING.md - Contribution guidelines

### Support
For issues, questions, or contributions:
- GitHub Issues: [Report bugs]
- GitHub Discussions: [Ask questions]
- Documentation: See SETUP_JOURNEY.md

---

**Built with ❤️ for the data community**
