import os
import re

# 遍历lib目录下的所有.dart文件
lib_dir = 'lib'

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 替换 code == 200 为 code == 0
            new_content = re.sub(r"code\s*==\s*200", "code == 0", content)
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Fixed: {file_path}')

print('Done!')
