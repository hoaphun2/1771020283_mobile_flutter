# Giai đoạn 1: Build code
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy file csproj và restore các thư viện
COPY *.csproj ./
RUN dotnet restore

# Copy toàn bộ code và build
COPY . ./
RUN dotnet publish -c Release -o out

# Giai đoạn 2: Chạy ứng dụng (Dùng image nhẹ hơn)
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .

# Mở cổng 80 trong container
EXPOSE 80

# Chạy file dll (Thay TenProjectCuaHoa.dll bằng tên file thật của bạn)
ENTRYPOINT ["dotnet", "PcmBackend.dll"]