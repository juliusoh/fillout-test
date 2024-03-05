npm run build
cp package*.json build
cd ./build
npm ci --production
zip -r ../.infra/artifact.zip .
cd ../.infra
