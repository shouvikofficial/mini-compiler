import subprocess
import os
import customtkinter as ctk
from tkinter import filedialog, messagebox

# ---------------- CONFIG ----------------
EXECUTABLE_NAME = "mini.exe"  # change if your exe name is different
# ----------------------------------------


def run_code():
    code = code_text.get("1.0", "end-1c")
    if not code.strip():
        messagebox.showwarning("No Code", "Please write some code before running.")
        return

    if not os.path.exists(EXECUTABLE_NAME):
        messagebox.showerror(
            "Executable Not Found",
            f"Could not find '{EXECUTABLE_NAME}' in the current folder."
        )
        return

    output_text.delete("1.0", "end")

    try:
        # IMPORTANT: send Ctrl+Z (\x1A) to signal EOF to your parser
        result = subprocess.run(
            [EXECUTABLE_NAME],
            input=code + "\x1A",   # <-- EOF for Windows console programs
            text=True,
            capture_output=True
        )

        if result.stdout:
            output_text.insert("end", result.stdout)

        if result.stderr:
            output_text.insert("end", "\n[stderr]\n" + result.stderr)

    except Exception as e:
        messagebox.showerror("Error Running Compiler", str(e))


def clear_code():
    code_text.delete("1.0", "end")


def clear_output():
    output_text.delete("1.0", "end")


def open_file():
    file_path = filedialog.askopenfilename(
        title="Open Mini Language File",
        filetypes=[("Text Files", "*.txt;*.mini;*.code;*.*"), ("All Files", "*.*")]
    )
    if file_path:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            code_text.delete("1.0", "end")
            code_text.insert("1.0", content)
        except Exception as e:
            messagebox.showerror("Error Opening File", str(e))


def save_code():
    file_path = filedialog.asksaveasfilename(
        title="Save Code",
        defaultextension=".txt",
        filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
    )
    if file_path:
        try:
            content = code_text.get("1.0", "end-1c")
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception as e:
            messagebox.showerror("Error Saving File", str(e))


def insert_sample():
    sample = (
        '/* Sample Program */\n'
        'name = "Shouvik";\n'
        'print name;\n\n'
        'i = 0;\n'
        'while (i < 3) {\n'
        '    print i;\n'
        '    i = i + 1;\n'
        '}\n\n'
        'for (j = 0; j < 3; j = j + 1) {\n'
        '    print j;\n'
        '}\n'
    )
    code_text.delete("1.0", "end")
    code_text.insert("1.0", sample)


def show_about():
    messagebox.showinfo(
        "About",
        "Mini Language Compiler GUI\n"
        "Frontend: Python + CustomTkinter\n"
        "Backend: FLEX + BISON compiler (mini.exe)\n"
        "Developer: Shouvik Dhali\n"
    )


# --------------- GUI SETUP ---------------

ctk.set_appearance_mode("dark")      # "light" or "dark"
ctk.set_default_color_theme("blue")  # "blue", "green", "dark-blue"

app = ctk.CTk()
app.title("Mini Language Compiler - GUI Frontend")
app.geometry("1000x600")

# Main layout: left = code editor, right = output
app.grid_rowconfigure(0, weight=1)
app.grid_columnconfigure(0, weight=3)
app.grid_columnconfigure(1, weight=2)

# -------- Left: Code Editor --------
left_frame = ctk.CTkFrame(app, corner_radius=10)
left_frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
left_frame.grid_rowconfigure(1, weight=1)
left_frame.grid_columnconfigure(0, weight=1)

title_label = ctk.CTkLabel(
    left_frame,
    text="Mini Language Code Editor",
    font=ctk.CTkFont(size=18, weight="bold")
)
title_label.grid(row=0, column=0, padx=10, pady=(10, 5), sticky="w")

code_text = ctk.CTkTextbox(
    left_frame,
    wrap="none",
    font=ctk.CTkFont(family="Consolas", size=13)
)
code_text.grid(row=1, column=0, sticky="nsew", padx=10, pady=5)

btn_frame = ctk.CTkFrame(left_frame)
btn_frame.grid(row=2, column=0, sticky="ew", padx=10, pady=10)
btn_frame.grid_columnconfigure((0, 1, 2, 3), weight=1)

run_button = ctk.CTkButton(btn_frame, text="Run Code", command=run_code)
run_button.grid(row=0, column=0, padx=5)

clear_code_button = ctk.CTkButton(btn_frame, text="Clear Code", command=clear_code)
clear_code_button.grid(row=0, column=1, padx=5)

open_button = ctk.CTkButton(btn_frame, text="Open File", command=open_file)
open_button.grid(row=0, column=2, padx=5)

save_button = ctk.CTkButton(btn_frame, text="Save Code", command=save_code)
save_button.grid(row=0, column=3, padx=5)

sample_button = ctk.CTkButton(left_frame, text="Insert Sample Program", command=insert_sample)
sample_button.grid(row=3, column=0, padx=10, pady=(0, 10), sticky="w")

# -------- Right: Output Panel --------
right_frame = ctk.CTkFrame(app, corner_radius=10)
right_frame.grid(row=0, column=1, sticky="nsew", padx=10, pady=10)
right_frame.grid_rowconfigure(1, weight=1)
right_frame.grid_columnconfigure(0, weight=1)

output_label = ctk.CTkLabel(
    right_frame,
    text="Program Output",
    font=ctk.CTkFont(size=18, weight="bold")
)
output_label.grid(row=0, column=0, padx=10, pady=(10, 5), sticky="w")

output_text = ctk.CTkTextbox(
    right_frame,
    wrap="none",
    font=ctk.CTkFont(family="Consolas", size=13)
)
output_text.grid(row=1, column=0, sticky="nsew", padx=10, pady=5)

output_btn_frame = ctk.CTkFrame(right_frame)
output_btn_frame.grid(row=2, column=0, sticky="ew", padx=10, pady=10)
output_btn_frame.grid_columnconfigure((0, 1), weight=1)

clear_output_button = ctk.CTkButton(output_btn_frame, text="Clear Output", command=clear_output)
clear_output_button.grid(row=0, column=0, padx=5)

about_button = ctk.CTkButton(output_btn_frame, text="About", command=show_about)
about_button.grid(row=0, column=1, padx=5)

# --------------- START APP ---------------
app.mainloop()
