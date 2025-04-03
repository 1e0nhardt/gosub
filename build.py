import os
import shutil
import subprocess

os.chdir("gd_extensions/gozen")
os.system("scons -j 16 target=template_debug")
os.chdir("../..")


def copy_file(src, dst):
    """
    拷贝指定文件到当前目录。

    :param src: 源文件路径
    :param dst: 目标文件路径
    :return: 无
    """
    # 参数校验
    if not os.path.exists(src):
        print(f"源文件路径 {src} 不存在。")
        return

    try:
        # 如果目标文件存在，则先删除它
        os.remove(dst)
    except OSError as e:
        print(f"删除目标文件时发生错误：{e}")

    try:
        # 执行文件拷贝操作
        shutil.copy(src, dst)
        print(f"文件 {src} 已成功拷贝至 {dst}。")
    except shutil.Error as e:
        print(f"文件拷贝过程中发生错误：{e}")
    except OSError as e:
        print(f"文件操作过程中发生错误：{e}")


subprocess.run(
    "scons -j 16 target=template_debug platform=windows",
    shell=True,
    cwd="gd_extensions/gozen"
)

copy_file("gd_extensions/gozen/libgozen.windows.template_debug.x86_64.dll",
          "src/bin/gozen/libgozen.windows.template_debug.x86_64.dll")
