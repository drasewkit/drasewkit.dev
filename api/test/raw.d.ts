// Vite の ?raw インポート（ファイルの中身を文字列で読む）の型
declare module '*?raw' {
  const content: string
  export default content
}
