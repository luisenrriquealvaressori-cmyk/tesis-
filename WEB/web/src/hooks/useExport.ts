/**
 * useExport — Hook reutilizable para exportar datos a CSV descargable.
 * No requiere librerías externas. Compatible con Excel, LibreOffice y Google Sheets.
 *
 * Uso:
 *   const { exportToCSV, exporting } = useExport();
 *   exportToCSV(data, columns, 'animales_export');
 */

import { useState } from 'react';

export interface ExportColumn {
  /** Cabecera de la columna en el CSV */
  header: string;
  /** Key del objeto o función transformadora */
  accessor: string | ((row: any) => string | number);
}

export const useExport = () => {
  const [exporting, setExporting] = useState(false);

  const exportToCSV = (
    data: any[],
    columns: ExportColumn[],
    filename: string = 'export'
  ) => {
    if (!data.length) return;
    setExporting(true);

    try {
      // BOM para que Excel detecte UTF-8 y muestre correctamente acentos y ñ
      const BOM = '\uFEFF';

      // Cabecera
      const headers = columns.map(c => `"${c.header}"`).join(';');

      // Filas
      const rows = data.map(row =>
        columns.map(col => {
          const val = typeof col.accessor === 'function'
            ? col.accessor(row)
            : row[col.accessor] ?? '';
          // Escapar comillas dentro del valor
          return `"${String(val).replace(/"/g, '""')}"`;
        }).join(';')
      );

      const csvContent = BOM + [headers, ...rows].join('\r\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);

      const link = document.createElement('a');
      link.setAttribute('href', url);
      link.setAttribute('download', `${filename}_${new Date().toISOString().slice(0, 10)}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  };

  return { exportToCSV, exporting };
};

// ── Columnas predefinidas por módulo ────────────────────────────────────────

export const ANIMAL_EXPORT_COLUMNS: ExportColumn[] = [
  { header: 'Identificación (Arete)', accessor: 'identificacion' },
  { header: 'Finca', accessor: 'finca' },
  { header: 'Ganadero', accessor: 'ganadero' },
  { header: 'Sexo', accessor: 'sexo' },
  { header: 'Raza', accessor: 'raza' },
  { header: 'Edad (meses)', accessor: 'edadMeses' },
  { header: 'Estado de Salud', accessor: 'estado' },
  { header: 'Fecha de Nacimiento', accessor: (r) => new Date(r.fechaNacimiento).toLocaleDateString('es-NI') },
];

export const GANADERO_EXPORT_COLUMNS: ExportColumn[] = [
  { header: 'Nombre', accessor: 'nombre' },
  { header: 'Teléfono', accessor: 'telefono' },
  { header: 'Municipio', accessor: 'municipio' },
  { header: 'Comarca', accessor: 'comarca' },
  { header: 'N° Fincas', accessor: 'totalFincas' },
  { header: 'N° Animales', accessor: 'totalAnimales' },
  { header: 'Fecha Registro', accessor: (r) => new Date(r.createdAt).toLocaleDateString('es-NI') },
];

export const SYNC_EXPORT_COLUMNS: ExportColumn[] = [
  { header: 'Ganadero', accessor: 'ganaderoNombre' },
  { header: 'Finca', accessor: 'fincaNombre' },
  { header: 'Tipo Entidad', accessor: 'tipoEntidad' },
  { header: 'Acción', accessor: 'accion' },
  { header: 'Latitud', accessor: (r) => r.latitud ?? '' },
  { header: 'Longitud', accessor: (r) => r.longitud ?? '' },
  { header: 'Fecha Sincronización', accessor: (r) => new Date(r.fechaSincronizacion).toLocaleString('es-NI') },
];
