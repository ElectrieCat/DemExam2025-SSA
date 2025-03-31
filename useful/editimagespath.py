#!/usr/bin/python3
import os
import shutil
import re

# Define directories
markdown_dir = '../'
image_dir = '../images/'

# Iterate over markdown files
for filename in os.listdir(markdown_dir):
    if filename.endswith('.md'):
        with open(os.path.join(markdown_dir, filename), 'r+') as file:
            content = file.read()
            # Find all image references
            images = re.findall(r'!\[.*?\]\((.*?)\)', content)
            for img in images:
                if not img.startswith('images/'):
                    # Move image to the dedicated directory
                    img_name = os.path.basename(img)
                    shutil.move(os.path.join(markdown_dir, img), os.path.join(image_dir, img_name))
                    # Update markdown reference
                    content = content.replace(img, f'images/{img_name}')
            # Write updated content back to the file
            file.seek(0)
            file.write(content)
            file.truncate()
