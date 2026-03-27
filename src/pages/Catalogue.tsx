import { useState, useEffect, useCallback } from 'react'
import { Package, Building2, Plus, Pencil, Trash2, Save, X, ChevronDown, ChevronUp } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { CatalogueItem, Department } from '../types'

type Tab = 'items' | 'departments'

const CATEGORY_OPTIONS = [
  { value: 'uniform', label: 'Uniform' },
  { value: 'hsk_linen', label: 'HSK Linen' },
  { value: 'fnb_linen', label: 'F&B Linen' },
] as const

const CATEGORY_LABELS: Record<string, string> = {
  uniform: 'Uniform',
  hsk_linen: 'HSK Linen',
  fnb_linen: 'F&B Linen',
}

const CATEGORY_PREFIX: Record<string, string> = {
  uniform: 'UNI',
  hsk_linen: 'HSK',
  fnb_linen: 'FNB',
}

/** Generate a 3-letter department code from the name */
function autoDeptCode(name: string, existingCodes: string[]): string {
  const clean = name.replace(/[^a-zA-Z]/g, '').toUpperCase()
  if (clean.length === 0) return ''
  // Try first 3 letters
  let code = clean.slice(0, 3)
  if (!existingCodes.includes(code)) return code
  // Try first letter + next consonants
  const consonants = clean.slice(1).replace(/[AEIOU]/g, '')
  if (consonants.length >= 2) {
    code = clean[0] + consonants.slice(0, 2)
    if (!existingCodes.includes(code)) return code
  }
  // Append digits
  for (let i = 1; i <= 9; i++) {
    code = clean.slice(0, 2) + String(i)
    if (!existingCodes.includes(code)) return code
  }
  return clean.slice(0, 3)
}

/** Generate the next item code for a category, e.g. UNI-024 */
function autoItemCode(category: string, existingCodes: string[]): string {
  const prefix = CATEGORY_PREFIX[category] || 'ITM'
  const pattern = new RegExp(`^${prefix}-(\\d+)$`)
  let max = 0
  for (const code of existingCodes) {
    const m = code.match(pattern)
    if (m) max = Math.max(max, parseInt(m[1]))
  }
  return `${prefix}-${String(max + 1).padStart(3, '0')}`
}

interface ItemForm {
  code: string
  name: string
  category: string
  price: string
  department_ids: string[]
  sort_order: string
}

interface DeptForm {
  code: string
  name: string
  can_submit_uniforms: boolean
  has_linen_items: boolean
}

const emptyItemForm: ItemForm = { code: '', name: '', category: 'uniform', price: '', department_ids: [], sort_order: '0' }
const emptyDeptForm: DeptForm = { code: '', name: '', can_submit_uniforms: true, has_linen_items: false }

export default function Catalogue() {
  const [tab, setTab] = useState<Tab>('items')

  // Items state
  const [items, setItems] = useState<CatalogueItem[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loadingItems, setLoadingItems] = useState(true)
  const [loadingDepts, setLoadingDepts] = useState(true)
  const [editingItemId, setEditingItemId] = useState<string | null>(null)
  const [addingItem, setAddingItem] = useState(false)
  const [itemForm, setItemForm] = useState<ItemForm>(emptyItemForm)
  const [savingItem, setSavingItem] = useState(false)

  // Multi-department mapping: item_id -> department_id[]
  const [itemDeptMap, setItemDeptMap] = useState<Record<string, string[]>>({})

  // Departments state
  const [showDeptForm, setShowDeptForm] = useState(false)
  const [editingDeptId, setEditingDeptId] = useState<string | null>(null)
  const [deptForm, setDeptForm] = useState<DeptForm>(emptyDeptForm)
  const [savingDept, setSavingDept] = useState(false)

  // Filters
  const [categoryFilter, setCategoryFilter] = useState('')
  const [deptFilter, setDeptFilter] = useState('')
  const [searchText, setSearchText] = useState('')

  // Notifications
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  // ── Fetch ──
  const fetchItems = useCallback(async () => {
    setLoadingItems(true)
    const { data } = await supabase
      .from('item_catalogue')
      .select('*')
      .order('sort_order')
    if (data) setItems(data)
    setLoadingItems(false)
  }, [])

  const fetchItemDeptMap = useCallback(async () => {
    const { data } = await supabase
      .from('item_department_access')
      .select('item_id, department_id')
    if (data) {
      const map: Record<string, string[]> = {}
      for (const row of data) {
        if (!map[row.item_id]) map[row.item_id] = []
        map[row.item_id].push(row.department_id)
      }
      setItemDeptMap(map)
    }
  }, [])

  const fetchDepartments = useCallback(async () => {
    setLoadingDepts(true)
    const { data } = await supabase
      .from('departments')
      .select('*')
      .order('name')
    if (data) setDepartments(data)
    setLoadingDepts(false)
  }, [])

  useEffect(() => {
    fetchItems()
    fetchDepartments()
    fetchItemDeptMap()
  }, [fetchItems, fetchDepartments, fetchItemDeptMap])

  function clearNotifications() {
    setError('')
    setSuccess('')
  }

  // ── Helpers ──
  function getDeptNames(itemId: string, fallbackDeptId: string | null): string {
    const deptIds = itemDeptMap[itemId]
    if (deptIds && deptIds.length > 0) {
      return deptIds.map((id) => departments.find((d) => d.id === id)?.name || '?').join(', ')
    }
    if (fallbackDeptId) {
      return departments.find((d) => d.id === fallbackDeptId)?.name || '—'
    }
    return 'All Departments'
  }

  // ── Item CRUD ──
  function handleAddItem() {
    clearNotifications()
    setEditingItemId(null)
    const code = autoItemCode('uniform', items.map((i) => i.code))
    setItemForm({ ...emptyItemForm, code })
    setAddingItem(true)
  }

  function handleEditItem(item: CatalogueItem) {
    clearNotifications()
    setAddingItem(false)
    setEditingItemId(item.id)
    const existingDeptIds = itemDeptMap[item.id] || []
    setItemForm({
      code: item.code,
      name: item.name,
      category: item.category,
      price: item.price != null ? String(item.price) : '',
      department_ids: existingDeptIds.length > 0 ? existingDeptIds : (item.department_id ? [item.department_id] : []),
      sort_order: String(item.sort_order),
    })
  }

  function handleCancelItem() {
    setAddingItem(false)
    setEditingItemId(null)
    setItemForm(emptyItemForm)
  }

  function toggleDeptInForm(deptId: string) {
    setItemForm((prev) => {
      const ids = prev.department_ids.includes(deptId)
        ? prev.department_ids.filter((id) => id !== deptId)
        : [...prev.department_ids, deptId]
      return { ...prev, department_ids: ids }
    })
  }

  function handleItemCategoryChange(category: string) {
    const code = editingItemId ? itemForm.code : autoItemCode(category, items.map((i) => i.code))
    setItemForm({ ...itemForm, category, code })
  }

  async function handleSaveItem(e: React.FormEvent) {
    e.preventDefault()
    clearNotifications()

    if (!itemForm.code.trim() || !itemForm.name.trim()) {
      setError('Code and name are required')
      return
    }

    // Check for duplicate item code
    const duplicateItem = items.find((i) => i.code === itemForm.code.trim() && i.id !== editingItemId)
    if (duplicateItem) {
      setError(`Item code "${itemForm.code.trim()}" is already used by "${duplicateItem.name}"`)
      return
    }

    setSavingItem(true)
    const payload = {
      code: itemForm.code.trim(),
      name: itemForm.name.trim(),
      category: itemForm.category,
      price: itemForm.price ? parseFloat(itemForm.price) : null,
      department_id: itemForm.department_ids.length === 1 ? itemForm.department_ids[0] : null,
      sort_order: parseInt(itemForm.sort_order) || 0,
    }

    let itemId = editingItemId

    if (editingItemId) {
      const { error: err } = await supabase
        .from('item_catalogue')
        .update(payload)
        .eq('id', editingItemId)
      if (err) {
        setError(err.message)
        setSavingItem(false)
        return
      }
    } else {
      const { data, error: err } = await supabase
        .from('item_catalogue')
        .insert(payload)
        .select('id')
        .single()
      if (err) {
        setError(err.message)
        setSavingItem(false)
        return
      }
      itemId = data.id
    }

    // Update junction table
    if (itemId) {
      await supabase.from('item_department_access').delete().eq('item_id', itemId)
      if (itemForm.department_ids.length > 0) {
        const rows = itemForm.department_ids.map((deptId) => ({
          item_id: itemId!,
          department_id: deptId,
        }))
        await supabase.from('item_department_access').insert(rows)
      }
    }

    setSuccess(`"${payload.name}" ${editingItemId ? 'updated' : 'created'}`)
    handleCancelItem()
    fetchItems()
    fetchItemDeptMap()
    setSavingItem(false)
  }

  async function handleToggleItem(item: CatalogueItem) {
    clearNotifications()
    const { error: err } = await supabase
      .from('item_catalogue')
      .update({ is_active: !item.is_active })
      .eq('id', item.id)
    if (err) {
      setError(err.message)
    } else {
      setSuccess(`"${item.name}" ${!item.is_active ? 'activated' : 'deactivated'}`)
      fetchItems()
    }
  }

  async function handleDeleteItem(item: CatalogueItem) {
    if (!window.confirm(`Delete "${item.name}"? This cannot be undone.`)) return
    clearNotifications()
    const { error: err } = await supabase
      .from('item_catalogue')
      .delete()
      .eq('id', item.id)
    if (err) {
      setError(err.message)
    } else {
      setSuccess(`"${item.name}" deleted`)
      fetchItems()
      fetchItemDeptMap()
    }
  }

  // ── Department CRUD ──
  function handleAddDept() {
    clearNotifications()
    setEditingDeptId(null)
    setDeptForm(emptyDeptForm)
    setShowDeptForm(true)
  }

  function handleDeptNameChange(name: string) {
    const existingCodes = departments.map((d) => d.code)
    const code = editingDeptId ? deptForm.code : autoDeptCode(name, existingCodes)
    setDeptForm({ ...deptForm, name, code })
  }

  function handleEditDept(dept: Department) {
    clearNotifications()
    setEditingDeptId(dept.id)
    setDeptForm({
      code: dept.code,
      name: dept.name,
      can_submit_uniforms: dept.can_submit_uniforms,
      has_linen_items: dept.has_linen_items,
    })
    setShowDeptForm(true)
  }

  function handleCancelDept() {
    setShowDeptForm(false)
    setEditingDeptId(null)
    setDeptForm(emptyDeptForm)
  }

  async function handleSaveDept(e: React.FormEvent) {
    e.preventDefault()
    clearNotifications()

    if (!deptForm.code.trim() || !deptForm.name.trim()) {
      setError('Code and name are required')
      return
    }

    const codeClean = deptForm.code.trim().toUpperCase().replace(/[^A-Z0-9]/g, '')
    if (codeClean.length !== 3) {
      setError('Department code must be exactly 3 characters')
      return
    }

    // Check for duplicate department code
    const duplicateDept = departments.find((d) => d.code === codeClean && d.id !== editingDeptId)
    if (duplicateDept) {
      setError(`Department code "${codeClean}" is already used by "${duplicateDept.name}"`)
      return
    }

    setSavingDept(true)
    const payload = {
      code: codeClean,
      name: deptForm.name.trim(),
      can_submit_uniforms: deptForm.can_submit_uniforms,
      has_linen_items: deptForm.has_linen_items,
    }

    if (editingDeptId) {
      const { error: err } = await supabase
        .from('departments')
        .update(payload)
        .eq('id', editingDeptId)
      if (err) {
        setError(err.message)
      } else {
        setSuccess(`"${payload.name}" updated`)
        handleCancelDept()
        fetchDepartments()
      }
    } else {
      const { error: err } = await supabase
        .from('departments')
        .insert(payload)
      if (err) {
        setError(err.message)
      } else {
        setSuccess(`"${payload.name}" created`)
        handleCancelDept()
        fetchDepartments()
      }
    }
    setSavingDept(false)
  }

  async function handleToggleDept(dept: Department) {
    clearNotifications()
    const { error: err } = await supabase
      .from('departments')
      .update({ is_active: !dept.is_active })
      .eq('id', dept.id)
    if (err) {
      setError(err.message)
    } else {
      setSuccess(`"${dept.name}" ${!dept.is_active ? 'activated' : 'deactivated'}`)
      fetchDepartments()
    }
  }

  async function handleDeleteDept(dept: Department) {
    const assignedItems = items.filter((i) => i.department_id === dept.id)
    if (assignedItems.length > 0) {
      setError(`Cannot delete "${dept.name}" — ${assignedItems.length} item(s) are assigned to it. Reassign or delete them first.`)
      return
    }
    if (!window.confirm(`Delete department "${dept.name}"? This cannot be undone.`)) return
    clearNotifications()
    const { error: err } = await supabase
      .from('departments')
      .delete()
      .eq('id', dept.id)
    if (err) {
      setError(err.message)
    } else {
      setSuccess(`"${dept.name}" deleted`)
      fetchDepartments()
    }
  }

  const filteredItems = items.filter((item) => {
    if (categoryFilter && item.category !== categoryFilter) return false
    if (deptFilter) {
      const deptIds = itemDeptMap[item.id]
      const matchesJunction = deptIds && deptIds.includes(deptFilter)
      const matchesLegacy = item.department_id === deptFilter
      if (!matchesJunction && !matchesLegacy) return false
    }
    if (searchText) {
      const s = searchText.toLowerCase()
      if (!item.name.toLowerCase().includes(s) && !item.code.toLowerCase().includes(s)) return false
    }
    return true
  })

  // ── Item Form Component ──
  function renderItemForm() {
    return (
      <form onSubmit={handleSaveItem} className="p-6 space-y-4 bg-navy/[0.02]">
        <h3 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
          {editingItemId ? <Pencil className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {editingItemId ? 'Edit Item' : 'Add New Item'}
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Code *</label>
            <input
              type="text"
              value={itemForm.code}
              onChange={(e) => setItemForm({ ...itemForm, code: e.target.value.toUpperCase() })}
              required
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold font-mono"
              placeholder="e.g. UNI-011"
            />
            {!editingItemId && <p className="text-xs text-gray-400 mt-1">Auto-generated from category — editable</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
            <input
              type="text"
              value={itemForm.name}
              onChange={(e) => setItemForm({ ...itemForm, name: e.target.value })}
              required
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
              placeholder="e.g. Polo Shirt"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Category *</label>
            <select
              value={itemForm.category}
              onChange={(e) => handleItemCategoryChange(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold bg-white"
            >
              {CATEGORY_OPTIONS.map((c) => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Price per unit (excl. VAT)</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">&pound;</span>
              <input
                type="number"
                step="0.01"
                min="0"
                value={itemForm.price}
                onChange={(e) => setItemForm({ ...itemForm, price: e.target.value })}
                className="w-full pl-7 pr-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                placeholder="0.00"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Sort Order</label>
            <input
              type="number"
              min="0"
              value={itemForm.sort_order}
              onChange={(e) => setItemForm({ ...itemForm, sort_order: e.target.value })}
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
            />
          </div>
        </div>

        {/* Multi-department checkboxes */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Visible to departments
            <span className="font-normal text-gray-400 ml-2">(none selected = visible to all)</span>
          </label>
          <div className="flex flex-wrap gap-3">
            {departments.filter((d) => d.is_active).map((dept) => (
              <label
                key={dept.id}
                className={`flex items-center gap-2 px-3 py-2 text-sm rounded-lg border cursor-pointer transition-colors ${
                  itemForm.department_ids.includes(dept.id)
                    ? 'bg-navy/10 border-navy/30 text-navy font-medium'
                    : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                }`}
              >
                <input
                  type="checkbox"
                  checked={itemForm.department_ids.includes(dept.id)}
                  onChange={() => toggleDeptInForm(dept.id)}
                  className="w-4 h-4 rounded border-gray-300 text-navy focus:ring-gold"
                />
                {dept.name}
              </label>
            ))}
          </div>
        </div>

        <div className="flex gap-2 pt-2">
          <button
            type="submit"
            disabled={savingItem}
            className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            {savingItem ? 'Saving...' : editingItemId ? 'Update Item' : 'Create Item'}
          </button>
          <button
            type="button"
            onClick={handleCancelItem}
            className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
          >
            <X className="w-4 h-4" />
            Cancel
          </button>
        </div>
      </form>
    )
  }

  // ── Render ──
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Catalogue</h1>
          <p className="text-sm text-gray-500 mt-1">Manage items, pricing, and departments</p>
        </div>
        <button
          onClick={tab === 'items' ? handleAddItem : handleAddDept}
          className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light"
        >
          <Plus className="w-4 h-4" />
          {tab === 'items' ? 'Add Item' : 'Add Department'}
        </button>
      </div>

      {/* Notifications */}
      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
      )}
      {success && (
        <div className="p-3 bg-green-50 border border-green-200 rounded-lg text-sm text-green-700">{success}</div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 p-1 rounded-lg w-fit">
        <button
          onClick={() => { setTab('items'); clearNotifications() }}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            tab === 'items' ? 'bg-white text-navy shadow-sm' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          <Package className="w-4 h-4" />
          Items & Pricing
        </button>
        <button
          onClick={() => { setTab('departments'); clearNotifications() }}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            tab === 'departments' ? 'bg-white text-navy shadow-sm' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          <Building2 className="w-4 h-4" />
          Departments
        </button>
      </div>

      {/* ── Items Tab ── */}
      {tab === 'items' && (
        <>
          {/* Add New Item Form (top, only for new items) */}
          {addingItem && (
            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              {renderItemForm()}
            </div>
          )}

          {/* Filters */}
          <div className="flex flex-wrap items-center gap-3">
            <input
              type="text"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Search items..."
              className="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold w-64"
            />
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold bg-white"
            >
              <option value="">All Categories</option>
              {CATEGORY_OPTIONS.map((c) => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </select>
            <select
              value={deptFilter}
              onChange={(e) => setDeptFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold bg-white"
            >
              <option value="">All Departments</option>
              {departments.map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </select>
          </div>

          {/* Items Table */}
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-2">
              <Package className="w-5 h-5 text-gray-500" />
              <h2 className="text-sm font-semibold text-gray-900">Items</h2>
              <span className="text-xs text-gray-400 ml-1">({filteredItems.length})</span>
              <span className="text-xs text-gray-400 ml-auto">Prices are excl. VAT</span>
            </div>

            {loadingItems ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 bg-gray-50">
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Code</th>
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Name</th>
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Category</th>
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Departments</th>
                      <th className="px-6 py-3 text-right font-medium text-gray-600">Price (excl. VAT)</th>
                      <th className="px-6 py-3 text-center font-medium text-gray-600">Status</th>
                      <th className="px-6 py-3 text-right font-medium text-gray-600">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredItems.map((item) => {
                      const isEditing = editingItemId === item.id
                      return (
                        <>
                          {/* Item row */}
                          <tr key={item.id} className={`border-b border-gray-100 last:border-0 transition-colors ${isEditing ? 'bg-navy/[0.03]' : 'hover:bg-gray-50'}`}>
                            <td className="px-6 py-3 font-mono text-xs text-gray-500">{item.code}</td>
                            <td className="px-6 py-3 font-medium text-gray-900">{item.name}</td>
                            <td className="px-6 py-3">
                              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-700">
                                {CATEGORY_LABELS[item.category] || item.category}
                              </span>
                            </td>
                            <td className="px-6 py-3 text-gray-600 text-xs">
                              {getDeptNames(item.id, item.department_id)}
                            </td>
                            <td className="px-6 py-3 text-right font-medium text-gray-900">
                              {item.price != null ? `\u00A3${Number(item.price).toFixed(2)}` : '—'}
                            </td>
                            <td className="px-6 py-3 text-center">
                              <button
                                onClick={() => handleToggleItem(item)}
                                className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium cursor-pointer transition-colors ${
                                  item.is_active
                                    ? 'bg-green-100 text-green-800 hover:bg-green-200'
                                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                                }`}
                              >
                                {item.is_active ? 'Active' : 'Inactive'}
                              </button>
                            </td>
                            <td className="px-6 py-3 text-right">
                              <div className="flex items-center justify-end gap-2">
                                <button
                                  onClick={() => isEditing ? handleCancelItem() : handleEditItem(item)}
                                  className={`inline-flex items-center gap-1 px-2.5 py-1.5 text-xs rounded-lg transition-colors ${
                                    isEditing
                                      ? 'text-gold bg-gold/10 hover:bg-gold/20 border border-gold/30'
                                      : 'text-navy bg-navy/5 hover:bg-navy/10 border border-navy/10'
                                  }`}
                                >
                                  {isEditing ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                                  {isEditing ? 'Close' : 'Edit'}
                                </button>
                                <button
                                  onClick={() => handleDeleteItem(item)}
                                  className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-lg transition-colors"
                                >
                                  <Trash2 className="w-3 h-3" />
                                </button>
                              </div>
                            </td>
                          </tr>

                          {/* Inline edit form below the row */}
                          {isEditing && (
                            <tr key={`${item.id}-edit`}>
                              <td colSpan={7} className="p-0 border-b border-navy/10">
                                {renderItemForm()}
                              </td>
                            </tr>
                          )}
                        </>
                      )
                    })}
                    {filteredItems.length === 0 && (
                      <tr>
                        <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                          {items.length === 0 ? 'No items found' : 'No items match the current filters'}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}

      {/* ── Departments Tab ── */}
      {tab === 'departments' && (
        <>
          {/* Add/Edit Department Form */}
          {showDeptForm && (
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <h2 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
                {editingDeptId ? <Pencil className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
                {editingDeptId ? 'Edit Department' : 'Add New Department'}
              </h2>
              <form onSubmit={handleSaveDept} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
                    <input
                      type="text"
                      value={deptForm.name}
                      onChange={(e) => handleDeptNameChange(e.target.value)}
                      required
                      className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                      placeholder="e.g. Housekeeping"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Code (3 letters) *</label>
                    <input
                      type="text"
                      value={deptForm.code}
                      onChange={(e) => setDeptForm({ ...deptForm, code: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 3) })}
                      required
                      maxLength={3}
                      className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold uppercase font-mono tracking-widest"
                      placeholder="ABC"
                    />
                    <p className="text-xs text-gray-400 mt-1">Auto-generated from name — editable</p>
                  </div>
                  <div className="flex items-end gap-6">
                    <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={deptForm.can_submit_uniforms}
                        onChange={(e) => setDeptForm({ ...deptForm, can_submit_uniforms: e.target.checked })}
                        className="w-4 h-4 rounded border-gray-300 text-navy focus:ring-gold"
                      />
                      Can submit uniforms
                    </label>
                  </div>
                  <div className="flex items-end gap-6">
                    <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={deptForm.has_linen_items}
                        onChange={(e) => setDeptForm({ ...deptForm, has_linen_items: e.target.checked })}
                        className="w-4 h-4 rounded border-gray-300 text-navy focus:ring-gold"
                      />
                      Has linen items
                    </label>
                  </div>
                </div>
                <div className="flex gap-2 pt-2">
                  <button
                    type="submit"
                    disabled={savingDept}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
                  >
                    <Save className="w-4 h-4" />
                    {savingDept ? 'Saving...' : editingDeptId ? 'Update Department' : 'Create Department'}
                  </button>
                  <button
                    type="button"
                    onClick={handleCancelDept}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
                  >
                    <X className="w-4 h-4" />
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Departments Table */}
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-2">
              <Building2 className="w-5 h-5 text-gray-500" />
              <h2 className="text-sm font-semibold text-gray-900">Departments</h2>
              <span className="text-xs text-gray-400 ml-1">({departments.length})</span>
            </div>

            {loadingDepts ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 bg-gray-50">
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Code</th>
                      <th className="px-6 py-3 text-left font-medium text-gray-600">Name</th>
                      <th className="px-6 py-3 text-center font-medium text-gray-600">Uniforms</th>
                      <th className="px-6 py-3 text-center font-medium text-gray-600">Linen</th>
                      <th className="px-6 py-3 text-center font-medium text-gray-600">Items</th>
                      <th className="px-6 py-3 text-center font-medium text-gray-600">Status</th>
                      <th className="px-6 py-3 text-right font-medium text-gray-600">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {departments.map((dept) => {
                      const itemCount = items.filter((i) => i.department_id === dept.id).length
                      return (
                        <tr key={dept.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                          <td className="px-6 py-3 font-mono text-xs text-gray-500">{dept.code}</td>
                          <td className="px-6 py-3 font-medium text-gray-900">{dept.name}</td>
                          <td className="px-6 py-3 text-center">
                            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                              dept.can_submit_uniforms ? 'bg-blue-50 text-blue-700' : 'bg-gray-50 text-gray-400'
                            }`}>
                              {dept.can_submit_uniforms ? 'Yes' : 'No'}
                            </span>
                          </td>
                          <td className="px-6 py-3 text-center">
                            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                              dept.has_linen_items ? 'bg-blue-50 text-blue-700' : 'bg-gray-50 text-gray-400'
                            }`}>
                              {dept.has_linen_items ? 'Yes' : 'No'}
                            </span>
                          </td>
                          <td className="px-6 py-3 text-center text-gray-600">{itemCount}</td>
                          <td className="px-6 py-3 text-center">
                            <button
                              onClick={() => handleToggleDept(dept)}
                              className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium cursor-pointer transition-colors ${
                                dept.is_active
                                  ? 'bg-green-100 text-green-800 hover:bg-green-200'
                                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                              }`}
                            >
                              {dept.is_active ? 'Active' : 'Inactive'}
                            </button>
                          </td>
                          <td className="px-6 py-3 text-right">
                            <div className="flex items-center justify-end gap-2">
                              <button
                                onClick={() => handleEditDept(dept)}
                                className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-navy bg-navy/5 hover:bg-navy/10 border border-navy/10 rounded-lg transition-colors"
                              >
                                <Pencil className="w-3 h-3" />
                                Edit
                              </button>
                              <button
                                onClick={() => handleDeleteDept(dept)}
                                className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-lg transition-colors"
                              >
                                <Trash2 className="w-3 h-3" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      )
                    })}
                    {departments.length === 0 && (
                      <tr>
                        <td colSpan={7} className="px-6 py-12 text-center text-gray-500">No departments found</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <p className="text-xs text-gray-400">
            Changes to departments will be reflected on the tablet app. Items assigned to a deleted department will need to be reassigned.
          </p>
        </>
      )}
    </div>
  )
}
