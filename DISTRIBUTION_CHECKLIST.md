# Distribution Checklist

Use this checklist before packaging and distributing Local Analytics Lab.

## Pre-Distribution

### Code Quality
- [ ] All services start successfully with `just up`
- [ ] Integration tests pass (Spark, Trino, Superset)
- [ ] No hardcoded personal paths or credentials
- [ ] All temporary files moved to `.temp-files/`
- [ ] No sensitive information in committed files

### Documentation
- [ ] README.md is up-to-date
- [ ] SETUP_JOURNEY.md reflects current state
- [ ] All URLs and credentials documented
- [ ] Installation instructions tested
- [ ] Troubleshooting section is complete

### Files & Structure
- [ ] LICENSE file present (MIT)
- [ ] CONTRIBUTING.md exists
- [ ] RELEASE_NOTES.md updated with version
- [ ] .gitignore properly configured
- [ ] .gitkeep files in empty directories
- [ ] install.sh is executable
- [ ] package.sh is executable

### Testing
- [ ] Fresh install works: `./install.sh`
- [ ] Services accessible at documented URLs
- [ ] Sample data loads correctly
- [ ] Superset shows Trino connection
- [ ] `just clean && just up` works

## Packaging

### Create Distribution
```bash
./package.sh
```

### Verify Package
- [ ] Check dist/ directory created
- [ ] .tar.gz file exists
- [ ] .zip file exists (for Windows users)
- [ ] SHA256 checksums generated
- [ ] Extract and test package contents

### Size Check
```bash
du -sh dist/local-analytics-lab-v*.tar.gz
```
Expected: ~50-100MB (without Docker images)

## Distribution

### GitHub Release
- [ ] Create git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Create GitHub Release
- [ ] Upload .tar.gz and .zip files
- [ ] Upload .sha256 checksum files
- [ ] Copy RELEASE_NOTES.md to release description
- [ ] Mark as latest release

### Documentation Sites
- [ ] Update any external documentation
- [ ] Post to relevant communities (if applicable)
- [ ] Update social media links (if applicable)

## Post-Distribution

### Monitoring
- [ ] Watch for issues in GitHub
- [ ] Respond to questions
- [ ] Collect feedback
- [ ] Plan next version improvements

### Version Management
- [ ] Update version number for next release
- [ ] Create CHANGELOG.md entry
- [ ] Tag issues for next milestone

---

## Quick Test Commands

```bash
# Full clean test
just clean
just up
sleep 60
just ps

# Integration tests
docker-compose exec spark-master /opt/spark/bin/spark-submit /opt/spark-apps/test_spark_minio.py
docker-compose exec trino trino --execute "SELECT COUNT(*) FROM hive.analytics.employees"

# Check Superset
curl -s http://localhost:8088/health | grep "OK"

# Package
./package.sh

# Verify archive
tar -tzf dist/local-analytics-lab-v1.0.0.tar.gz | head -20
```

---

## Common Issues Before Distribution

### Port Conflicts
- [ ] Document all ports in README
- [ ] Provide alternatives if conflicts occur

### File Permissions
- [ ] All shell scripts executable
- [ ] No files with 777 permissions

### Hardcoded Paths
- [ ] Use relative paths only
- [ ] No `/Users/username/` paths
- [ ] No absolute paths to local machine

### Credentials
- [ ] Default credentials documented
- [ ] Security warning included
- [ ] Instructions for changing passwords

---

## Version History

### v1.0.0 (Current)
- Initial release
- Complete analytics stack
- Auto-configuration
- Sample dataset

---

**Last Verified:** [Date]
**Verified By:** [Name]
