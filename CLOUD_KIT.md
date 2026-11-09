# cloud-kit

Drop-in rules for Cursor Cloud Agents on J H repos. Overlay onto a repo root (does not replace the project README):

```bash
tar xzf cloud-kit.tar.gz
cp -a cloud-kit/AGENTS.md .
cp -a cloud-kit/.cursor cloud-kit/scripts cloud-kit/ATTRIBUTION.md cloud-kit/CLOUD_KIT.md .
bash scripts/check.sh
```

Do not commit Falcon data (`labels.sqlite`, `kg.sqlite`, `.env`, strategy notes). `scripts/check.sh` enforces the basics.
