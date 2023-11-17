import MainLayout from "@/components/layouts/MainLayout";
import ScreenAtomRenderer from "@/components/ScreenAtomRenderer";
import { Toaster } from '@/components/ui/toaster'

function App() {
  return (
      <MainLayout>
          <ScreenAtomRenderer/>
          <Toaster />
      </MainLayout>
  );
}

export default App;
