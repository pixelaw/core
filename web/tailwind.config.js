/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        'new-primary': 'hsl(var(--new-primary))',
        'brand-blackAccent': 'hsl(var(--brand-blackAccent))',
        'brand-redAccent': 'hsl(var(--brand-redAccent))',
        'brand-body': 'hsl(var(--brand-body))',
        'brand-yellow': 'hsl(var(--brand-yellow))',
        'brand-violet': 'hsl(var(--brand-violet))',
        'brand-violetAccent': 'hsl(var(--brand-violetAccent))',
        'brand-violetAccent01': 'hsl(var(--brand-violetAccent01))',
        'brand-violetAccent02': 'hsl(var(--brand-violetAccent02))',
        'brand-violetAccent03': 'hsl(var(--brand-violetAccent03))',
        'brand-violetAccent04': 'hsl(var(--brand-violetAccent04))',
        'brand-skyblue': 'hsl(var(--brand-skyblue))',
        'brand-danger': 'hsl(var(--brand-danger))',
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      padding: {
        'xs': '15px',
        'sm': '30px',
        'md': '40px',
        'lg': '60px',
        'xl': '100px'
      },
      margin: {
        'xs': '15px',
        'sm': '30px',
        'md': '40px',
        'lg': '60px',
        'xl': '100px'
      },
      spacing: {
        'xs': '15px',
        'sm': '30px',
        'md': '40px',
        'lg': '60px',
        'xl': '100px'
      },
      fontFamily: {
        'silkscreen': ["Silkscreen", 'cursive'],
        'noto-sans': ["Noto Sans", 'sans-serif'],
        'emoji': ["Noto Emoji", 'sans-serif']
      },
      backgroundImage:{
        'main': "url('/assets/background/main.png')",
        'gradient-default': "linear-gradient(90deg, #00000000 0%, #000000 37%, #000000 62%, #00000000 100%)"
      },
      dropShadow: {
        'card': '0px 3px 12px #0000008A',
        'btn-default': '0px 3px 12px #000000A6'
      },
      keyframes: {
        "accordion-down": {
          from: {height: 0},
          to: {height: "var(--radix-accordion-content-height)"},
        },
        "accordion-up": {
          from: {height: "var(--radix-accordion-content-height)"},
          to: {height: 0},
        },
        "fade-in": {
          from: {opacity:0},
          to: {opacity:1},

        },
        "fade-out": {
          from: {opacity:1},
          to: {opacity:0}
        },
        "slide-left": {
          '0%': {width: '72px', display: 'none'},
          '100%': {width: '237px'},
        },
        "slide-right": {
          '0%': {width: '237px'},
          '100%': {width: '72px'},
        },
        "slide-left-icon": {
          '0%': {width: '72px'},
          '100%': {width: '253px'},
        },
        "slide-right-icon": {
          '0': {width: '253px'},
          '100': {width: '72px'},
        }
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.3s ease-in-out forwards",
        "fade-out": "fade-out 0.3s ease-in-out forwards",
        "slide-left": "slide-left 0.3s linear forwards",
        "slide-right": "slide-right 0.3s linear forwards",
        "slide-left-icon": "slide-left-icon 0.3s linear forwards",
        "slide-right-icon": "slide-right-icon 0.3s linear forwards",
      },
      boxShadow: {
        glow: '0 0 10px 0 rgba(255, 255, 255, 1)',
      }
    },
  },
  plugins: [require("tailwindcss-animate")],
}
