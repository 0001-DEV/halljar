# 📱 Halljar - Mobile PWA & Estate Commerce Platform

A hyper-local commerce web app and installable Mobile PWA for estates (Warewa, Citi-View, Arepo, Opic, Ibafo).

---

## 🚀 How to Host on Vercel (Share Link with Friends)

You can host Halljar on Vercel in **under 2 minutes** using either **GitHub** or the **Vercel CLI**:

### Option 1: 1-Click via GitHub & Vercel Dashboard (Recommended)
1. Create a new repository on your GitHub (e.g. `halljar`).
2. Push this project to GitHub:
   ```bash
   git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/halljar.git
   git push -u origin main
   ```
3. Visit [vercel.com](https://vercel.com) and log in.
4. Click **"Add New..."** -> **"Project"**.
5. Select your `halljar` repository and click **Deploy**.
6. That's it! Vercel will give you a live production link (e.g. `https://halljar-xxx.vercel.app`) that you can immediately send to all your friends.

---

### Option 2: Deploy directly via Vercel CLI
From this project directory (`halljar`), run:
```bash
npx vercel
```
- When prompted:
  - `Set up and deploy?`: `y`
  - `Which scope?`: Choose your Vercel account
  - `Link to existing project?`: `n`
  - `What's your project's name?`: `halljar`
  - `In which directory is your code located?`: `./`
  - `Want to modify settings?`: `n`
- Run `npx vercel --prod` to deploy to live production.

---

## 📲 How to Install as a Mobile App on Phones

### 🤖 Android (Google Chrome / Brave)
1. Open your live link (or `http://<your-ip>:3000`) on Google Chrome.
2. An **"📲 App"** button appears in the top navigation bar, or Chrome will show an "Add to Home screen" banner.
3. Tap **"Install App"** to install it directly to your app drawer and home screen.

### 🍎 iPhone / iPad (Safari)
1. Open your live link in **Safari**.
2. Tap the **Share** button ⎋ at the bottom bar.
3. Scroll down and tap **"Add to Home Screen"** ➕.
4. Tap **Add** in the top right.
5. The Halljar icon will appear on your home screen and open like a native iOS app with full-screen experience and safe-area support.

---

## 💻 Local Development
Run the local server with:
```bash
node server/server.js
```
Open [http://localhost:3000](http://localhost:3000) in your browser.
