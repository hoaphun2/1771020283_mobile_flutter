import os

# Tạo thư mục assets
os.makedirs('assets', exist_ok=True)

# Danh sách file cần tạo
files = [
    'court1.jpg',
    'court2.jpg', 
    'court3.jpg',
    'court4.jpg',
    'momo.png',
    'zalopay.png',
    'vnpay.png',
    'vcb.png'
]

# Tạo file txt thay thế (tạm thời)
for file in files:
    with open(f'assets/{file}', 'w') as f:
        f.write('This is a placeholder for ' + file)
    print(f'Created: assets/{file}')