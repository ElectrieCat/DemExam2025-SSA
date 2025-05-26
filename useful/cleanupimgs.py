import os
import re

def get_referenced_images(markdown_file):
    """Извлекает имена файлов изображений из markdown файла."""
    referenced_images = set()
    try:
        with open(markdown_file, 'r', encoding='utf-8') as f:
            content = f.read()
            # Находим все имена файлов изображений в формате ![](images/filename)
            matches = re.findall(r'!\[\]\(images/([^)]+)\)', content)
            referenced_images.update(matches)
        return referenced_images
    except FileNotFoundError:
        print(f"Ошибка: Файл {markdown_file} не найден")
        return set()
    except Exception as e:
        print(f"Ошибка при чтении markdown файла: {e}")
        return set()

def delete_unused_images(images_dir, referenced_images):
    """Удаляет изображения из папки, которые не упоминаются в markdown."""
    try:
        # Получаем список всех файлов в папке images
        all_images = set(os.listdir(images_dir))
        # Находим изображения, которые не упоминаются
        unused_images = all_images - referenced_images
        
        if not unused_images:
            print("Не найдено неиспользуемых изображений")
            return
            
        # Удаляем неиспользуемые изображения
        for image in unused_images:
            image_path = os.path.join(images_dir, image)
            try:
                os.remove(image_path)
                print(f"Удалено: {image_path}")
            except Exception as e:
                print(f"Ошибка при удалении {image_path}: {e}")
                
        print(f"Удалено изображений: {len(unused_images)}")
    except FileNotFoundError:
        print(f"Ошибка: Папка {images_dir} не найдена")
    except Exception as e:
        print(f"Ошибка при обработке папки: {e}")

def main():
    markdown_file = "../DemExamGuide.md"  # Укажите имя вашего markdown файла
    images_dir = "../images"  # Укажите путь к папке с изображениями
    
    # Получаем список использованных изображений
    referenced_images = get_referenced_images(markdown_file)
    
    # Удаляем неиспользуемые изображения
    delete_unused_images(images_dir, referenced_images)

if __name__ == "__main__":
    main()
